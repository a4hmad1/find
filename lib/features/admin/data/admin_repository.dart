import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/domain/notification_type.dart';
import '../../../core/domain/post_status.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/json.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/models/report_model.dart';

/// Counters shown on the moderation dashboard.
class AdminStats {
  const AdminStats({
    required this.posts,
    required this.pendingPosts,
    required this.openReports,
    required this.users,
    required this.bannedUsers,
  });

  final int posts;
  final int pendingPosts;
  final int openReports;
  final int users;
  final int bannedUsers;
}

class AdminRepository {
  AdminRepository(this._client, this._images, this._profiles);

  final SupabaseClient _client;
  final ImageUploadService _images;
  final ProfileGuard _profiles;

  /// Whether the caller may see the moderation area at all.
  ///
  /// Used to decide whether to render the entry point, rather than letting the
  /// user tap through to a screen that can only fail.
  Future<bool> canModerate() async {
    final profile = await _profiles.currentOrNull();
    return profile != null && !profile.isBanned && profile.role.canModerate;
  }

  Future<AdminStats> stats() {
    return guardFailures(() async {
      await _profiles.requireModerator();
      // Issued together rather than in sequence: three independent counts had
      // no reason to cost three serial round-trips.
      final results = await Future.wait([
        _client.from(DbTables.posts).select('id,status'),
        _client.from(DbTables.reports).select('id,status'),
        _client.from(DbTables.profiles).select('id,is_banned'),
      ]);
      final posts = results[0];
      final reports = results[1];
      final users = results[2];

      return AdminStats(
        posts: posts.length,
        pendingPosts: posts
            .where((row) => row['status'] == PostStatus.pending.wire)
            .length,
        openReports: reports
            .where((row) => row['status'] == ReportStatus.pending.wire)
            .length,
        users: users.length,
        bannedUsers: users.where((row) => row['is_banned'] == true).length,
      );
    });
  }

  Future<List<PostModel>> posts({PostStatus? status}) {
    return guardFailures(() async {
      await _profiles.requireModerator();
      var request = _client
          .from(DbTables.posts)
          .select(DbSelects.postWithImagesAndProfile);
      if (status != null) {
        request = request.eq('status', status.wire);
      }
      final rows = await request.order('created_at', ascending: false);
      return rows
          .map(
            (row) => PostModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    });
  }

  Future<List<ReportModel>> reports() {
    return guardFailures(() async {
      await _profiles.requireModerator();
      final rows = await _client
          .from(DbTables.reports)
          .select()
          .order('created_at', ascending: false);
      return rows
          .map(
            (row) =>
                ReportModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    });
  }

  Future<List<ProfileModel>> users() {
    return guardFailures(() async {
      await _profiles.requireModerator();
      final rows = await _client
          .from(DbTables.profiles)
          .select(DbSelects.publicProfile)
          .order('created_at', ascending: false);
      return rows
          .map(
            (row) =>
                ProfileModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    });
  }

  /// Moves a post to [status] and tells its author why.
  Future<void> updatePostStatus(String postId, PostStatus status) {
    return guardFailures(() async {
      await _profiles.requireModerator();
      final post = await _client
          .from(DbTables.posts)
          .select('user_id')
          .eq('id', postId)
          .single();

      await _client
          .from(DbTables.posts)
          .update({
            'status': status.wire,
            'updated_at': DateTime.now().toUtcIso(),
          })
          .eq('id', postId);

      final type = switch (status) {
        PostStatus.approved => NotificationType.postApproved,
        PostStatus.rejected => NotificationType.postRejected,
        PostStatus.returned => NotificationType.postReturned,
        PostStatus.pending || PostStatus.closed => NotificationType.adminNotice,
      };
      await _client.from(DbTables.notifications).insert({
        'user_id': post['user_id'],
        'title': type.label,
        'body': type.label,
        'type': type.wire,
        'related_post_id': postId,
      });
    });
  }

  Future<void> deletePost(String postId) {
    return guardFailures(() async {
      await _profiles.requireModerator();
      // Storage objects are not covered by the row's delete cascade.
      await _images.deletePostImages(postId);
      await _client.from(DbTables.posts).delete().eq('id', postId);
    });
  }

  Future<void> resolveReport(String reportId) {
    return guardFailures(() async {
      await _profiles.requireModerator();
      await _client
          .from(DbTables.reports)
          .update({'status': ReportStatus.resolved.wire})
          .eq('id', reportId);
    });
  }

  Future<void> banUser(String userId, {required bool banned}) {
    return guardFailures(() async {
      final moderator = await _profiles.requireModerator();
      if (moderator.id == userId) {
        throw const ValidationFailure('ناتوانیت خۆت ڕابگریت');
      }
      await _client
          .from(DbTables.profiles)
          .update({
            'is_banned': banned,
            'updated_at': DateTime.now().toUtcIso(),
          })
          .eq('id', userId);
    });
  }

  /// Sends one notification to every active user.
  Future<void> sendAnnouncement({required String title, required String body}) {
    return guardFailures(() async {
      await _profiles.requireModerator();
      final trimmedTitle = title.trim();
      final trimmedBody = body.trim();
      if (trimmedTitle.isEmpty || trimmedBody.isEmpty) {
        throw const ValidationFailure('تکایە ناونیشان و دەق بنووسە');
      }

      final users = await _client
          .from(DbTables.profiles)
          .select('id')
          .eq('is_banned', false);
      if (users.isEmpty) return;

      await _client.from(DbTables.notifications).insert([
        for (final user in users)
          {
            'user_id': user['id'],
            'title': trimmedTitle,
            'body': trimmedBody,
            'type': NotificationType.adminNotice.wire,
          },
      ]);
    });
  }
}
