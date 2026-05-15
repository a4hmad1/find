import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/profile_model.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<User?> get authStateChanges async* {
    yield _client.auth.currentUser;
    await for (final state in _client.auth.onAuthStateChange) {
      final user = state.session?.user;
      if (user != null) {
        await upsertProfile(user);
      }
      yield user;
    }
  }

  Future<void> signInWithGitHub() async {
    final didLaunch = await _client.auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: kIsWeb ? null : 'krd.gov.find.find://login-callback',
      scopes: 'read:user user:email',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    if (!didLaunch) {
      throw const AppException('چوونەژوورەوە سەرکەوتوو نەبوو');
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<ProfileModel?> currentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return upsertProfile(user);
  }

  Future<ProfileModel> upsertProfile(User user) async {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final githubId = _firstText(metadata, const [
      'provider_id',
      'sub',
      'id',
    ], fallback: user.id);
    final username = _firstText(metadata, const [
      'user_name',
      'preferred_username',
      'login',
      'name',
    ], fallback: 'github');
    final displayName = _firstText(metadata, const [
      'full_name',
      'name',
      'user_name',
    ], fallback: username);
    final avatarUrl = _firstText(metadata, const [
      'avatar_url',
      'picture',
    ], fallback: '');
    final email = user.email ?? metadata['email']?.toString();

    final row = await _client
        .from(DbTables.profiles)
        .upsert({
          'auth_user_id': user.id,
          'github_id': githubId,
          'github_username': username,
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'email': email,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'auth_user_id')
        .select(DbSelects.publicProfile)
        .single();

    return ProfileModel.fromJson(row);
  }

  String _firstText(
    Map<String, dynamic> metadata,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = metadata[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }
}
