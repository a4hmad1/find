import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/profile_model.dart';

class AuthRepository {
  AuthRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileGuard _profiles;

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Raw auth events from GoTrue, including the deep-link callback.
  Stream<AuthState> get authEvents => _client.auth.onAuthStateChange;

  /// The signed-in user, starting with the session restored at launch.
  ///
  /// The profile row is upserted only on events that can actually carry new
  /// identity data. The previous implementation upserted on *every* event,
  /// which meant each hourly token refresh issued a pointless write — and, more
  /// importantly, made a transient database error look like a sign-out.
  Stream<User?> get authStateChanges async* {
    yield _client.auth.currentUser;

    await for (final state in _client.auth.onAuthStateChange) {
      final user = state.session?.user;

      if (user != null && _shouldSyncProfile(state.event)) {
        // A failed sync must not break the auth stream: the user is genuinely
        // signed in, and the profile is re-read on next use.
        try {
          await upsertProfile(user);
        } on Object catch (error, stackTrace) {
          debugPrint('Profile sync failed: ${AppFailure.from(error)}');
          assert(() {
            debugPrintStack(stackTrace: stackTrace);
            return true;
          }());
        }
      }

      if (state.event == AuthChangeEvent.signedOut) {
        _profiles.refresh();
      }

      yield user;
    }
  }

  static bool _shouldSyncProfile(AuthChangeEvent event) => switch (event) {
    AuthChangeEvent.signedIn ||
    AuthChangeEvent.initialSession ||
    AuthChangeEvent.userUpdated => true,
    _ => false,
  };

  /// Starts the GitHub OAuth flow.
  ///
  /// On mobile the browser returns to the app through the
  /// [AuthConfig.nativeRedirectUrl] deep link, which `supabase_flutter` picks
  /// up and exchanges for a session; the resulting `signedIn` event is what
  /// drives navigation. On web, Supabase redirects the tab back to the app's
  /// own origin, so no explicit redirect URL is passed.
  Future<void> signInWithGitHub() {
    return guardFailures(() async {
      final didLaunch = await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : AuthConfig.nativeRedirectUrl,
        scopes: AuthConfig.githubScopes,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!didLaunch) {
        throw const AuthFailure(
          message: 'نەتوانرا وێبگەڕ بکرێتەوە، تکایە دووبارە هەوڵبدەرەوە',
        );
      }
    });
  }

  Future<void> signOut() {
    return guardFailures(() async {
      await _client.auth.signOut();
      _profiles.refresh();
    });
  }

  /// The signed-in user's profile, or null when signed out.
  Future<ProfileModel?> currentProfile() {
    return guardFailures(() async {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return upsertProfile(user);
    });
  }

  /// Mirrors the GitHub identity into the `profiles` table.
  ///
  /// GitHub spreads the same information across differently-named metadata
  /// keys depending on how the account is configured, so each field is resolved
  /// from an ordered list of candidates.
  Future<ProfileModel> upsertProfile(User user) {
    return guardFailures(() async {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final username = _firstNonEmpty(metadata, const [
        'user_name',
        'preferred_username',
        'login',
        'name',
      ], fallback: 'github');

      final row = await _client
          .from(DbTables.profiles)
          .upsert({
            'auth_user_id': user.id,
            'github_id': _firstNonEmpty(metadata, const [
              'provider_id',
              'sub',
              'id',
            ], fallback: user.id),
            'github_username': username,
            'display_name': _firstNonEmpty(metadata, const [
              'full_name',
              'name',
              'user_name',
            ], fallback: username),
            'avatar_url': _firstNonEmpty(metadata, const [
              'avatar_url',
              'picture',
            ], fallback: ''),
            'email': user.email ?? metadata['email']?.toString(),
            'updated_at': DateTime.now().toUtcIso(),
          }, onConflict: 'auth_user_id')
          .select(DbSelects.publicProfile)
          .single();

      final profile = ProfileModel.fromJson(row);
      // The cached copy is now stale by definition.
      _profiles.refresh();
      return profile;
    });
  }

  /// The first of [keys] present in [metadata] with a non-blank value.
  static String _firstNonEmpty(
    Map<String, dynamic> metadata,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = metadata[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }
}
