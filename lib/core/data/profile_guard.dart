import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/profile_model.dart';
import '../constants/app_constants.dart';
import '../errors/app_failure.dart';

/// Resolves the signed-in user's profile row and enforces access rules.
///
/// Four repositories previously carried a byte-identical private `_profile()`
/// method, each issuing its own `SELECT` on every call — so a single "send
/// message" action cost two round-trips before it did any work. This centralises
/// the lookup and memoises it for the lifetime of the signed-in session.
///
/// The cache is keyed by auth user id and dropped whenever that changes, so
/// signing out or switching accounts cannot leak a stale profile. Ban and role
/// changes made while a session is open are still enforced server-side by
/// row-level security; [refresh] forces a re-read when the client needs to see
/// them immediately.
class ProfileGuard {
  ProfileGuard(this._client);

  final SupabaseClient _client;

  ProfileModel? _cached;
  String? _cachedAuthUserId;

  /// The profile of the signed-in user, or null when signed out.
  ///
  /// Unlike [require] this does not throw, so callers rendering optional
  /// account UI do not have to catch.
  Future<ProfileModel?> currentOrNull() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) {
      _invalidate();
      return null;
    }
    if (_cached != null && _cachedAuthUserId == authUserId) return _cached;
    final profile = await _fetch(authUserId);
    if (profile != null) {
      _cached = profile;
      _cachedAuthUserId = authUserId;
    }
    return profile;
  }

  /// The profile of the signed-in user.
  ///
  /// Throws [AuthFailure] when signed out, [NotFoundFailure] when the row is
  /// missing, and [PermissionFailure] when the account is banned.
  Future<ProfileModel> require() async {
    final authUserId = _client.auth.currentUser?.id;
    if (authUserId == null) throw const AuthFailure();

    final profile = await currentOrNull();
    if (profile == null) {
      throw const NotFoundFailure(message: 'هەژمارەکە نەدۆزرایەوە');
    }
    if (profile.isBanned) {
      throw const PermissionFailure(message: 'هەژمارەکەت ڕاگیراوە');
    }
    return profile;
  }

  /// The profile of the signed-in user, which must hold a moderating role.
  ///
  /// This is a UX guard only — it keeps the moderation screens from rendering
  /// for ordinary users. Authorisation is enforced by RLS policies on the
  /// server, which is what actually stops a tampered client.
  Future<ProfileModel> requireModerator() async {
    final profile = await require();
    if (!profile.role.canModerate) throw const PermissionFailure();
    return profile;
  }

  /// Drops the memoised profile so the next read hits the database.
  ///
  /// Call after any write that changes the caller's own profile row.
  void refresh() => _invalidate();

  void _invalidate() {
    _cached = null;
    _cachedAuthUserId = null;
  }

  Future<ProfileModel?> _fetch(String authUserId) async {
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authUserId)
        .limit(1);
    if (rows.isEmpty) return null;
    return ProfileModel.fromJson(rows.first);
  }
}
