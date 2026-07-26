import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileGuard _profiles;

  Future<ProfileModel?> getByAuthUserId(String authUserId) {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.profiles)
          .select(DbSelects.publicProfile)
          .eq('auth_user_id', authUserId)
          .limit(1);
      if (rows.isEmpty) return null;
      return ProfileModel.fromJson(rows.first);
    });
  }

  Future<ProfileModel> currentProfile() => guardFailures(_profiles.require);

  Future<List<PostModel>> myPosts() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final rows = await _client
          .from(DbTables.posts)
          .select(DbSelects.postWithImages)
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);
      return _parsePosts(rows);
    });
  }

  Future<List<PostModel>> savedPosts() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final rows = await _client
          .from(DbTables.savedPosts)
          .select(DbSelects.savedPostJoin)
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);
      // A saved row whose post has since been deleted comes back with a null
      // join, so those are dropped rather than rendered as blank cards.
      return rows
          .map((row) => row['posts'])
          .whereType<Map<String, dynamic>>()
          .map(PostModel.fromJson)
          .toList();
    });
  }

  /// Ids of the caller's saved posts, for rendering bookmark state.
  Future<Set<String>> savedPostIds() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final rows = await _client
          .from(DbTables.savedPosts)
          .select('post_id')
          .eq('user_id', profile.id);
      return rows
          .map((row) => row.asString('post_id'))
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  Future<void> savePost(String postId) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client.from(DbTables.savedPosts).upsert({
        'user_id': profile.id,
        'post_id': postId,
      }, onConflict: 'user_id,post_id');
    });
  }

  Future<void> removeSavedPost(String postId) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client
          .from(DbTables.savedPosts)
          .delete()
          .eq('user_id', profile.id)
          .eq('post_id', postId);
    });
  }

  /// Deactivates the caller's account and signs them out.
  ///
  /// This is a soft delete: the row is flagged rather than removed so that
  /// posts and message threads other users are relying on stay intact. The user
  /// is told as much on the confirmation dialog.
  Future<void> deleteAccount() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client
          .from(DbTables.profiles)
          .update({'is_banned': true, 'updated_at': DateTime.now().toUtcIso()})
          .eq('id', profile.id);
      await _client.auth.signOut();
      _profiles.refresh();
    });
  }

  List<PostModel> _parsePosts(List<dynamic> rows) {
    return rows
        .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
