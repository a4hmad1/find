import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel?> getByAuthUserId(String authUserId) async {
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authUserId)
        .limit(1);
    if (rows.isEmpty) return null;
    return ProfileModel.fromJson(rows.first);
  }

  Future<ProfileModel> currentProfile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) throw const AppException('تکایە بچۆ ژوورەوە');
    final profile = await getByAuthUserId(authId);
    if (profile == null) throw const AppException('هەژمارەکە نەدۆزرایەوە');
    return profile;
  }

  Future<List<PostModel>> myPosts() async {
    final profile = await currentProfile();
    final rows = await _client
        .from(DbTables.posts)
        .select('*, post_images(*)')
        .eq('user_id', profile.id)
        .order('created_at', ascending: false);
    return rows
        .map<PostModel>(
          (row) => PostModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<PostModel>> savedPosts() async {
    final profile = await currentProfile();
    final rows = await _client
        .from(DbTables.savedPosts)
        .select(
          'posts(*, post_images(*), profiles(${DbSelects.publicProfile}))',
        )
        .eq('user_id', profile.id)
        .order('created_at', ascending: false);
    return rows
        .map<PostModel?>((row) {
          final post = row['posts'];
          if (post is! Map) return null;
          return PostModel.fromJson(Map<String, dynamic>.from(post));
        })
        .whereType<PostModel>()
        .toList();
  }

  Future<void> savePost(String postId) async {
    final profile = await currentProfile();
    await _client.from(DbTables.savedPosts).upsert({
      'user_id': profile.id,
      'post_id': postId,
    }, onConflict: 'user_id,post_id');
  }

  Future<void> removeSavedPost(String postId) async {
    final profile = await currentProfile();
    await _client
        .from(DbTables.savedPosts)
        .delete()
        .eq('user_id', profile.id)
        .eq('post_id', postId);
  }

  Future<void> deleteAccount() async {
    final profile = await currentProfile();
    await _client
        .from(DbTables.profiles)
        .update({
          'is_banned': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', profile.id);
    await _client.auth.signOut();
  }
}
