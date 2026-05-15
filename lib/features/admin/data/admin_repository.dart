import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/models/report_model.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel> requireAdmin() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) throw const AppException('تکایە بچۆ ژوورەوە');
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authId)
        .limit(1);
    if (rows.isEmpty) throw const AppException('هەژمارەکە نەدۆزرایەوە');
    final profile = ProfileModel.fromJson(rows.first);
    if (!profile.isAdmin) throw const AppException('ڕێگەپێدراو نیت');
    return profile;
  }

  Future<Map<String, int>> stats() async {
    await requireAdmin();
    final posts = await _client.from(DbTables.posts).select('id,status');
    final reports = await _client.from(DbTables.reports).select('id,status');
    final users = await _client.from(DbTables.profiles).select('id,is_banned');
    return {
      'posts': posts.length,
      'pending': posts.where((row) => row['status'] == DbValues.pending).length,
      'reports': reports.where((row) => row['status'] == 'pending').length,
      'users': users.length,
      'banned': users.where((row) => row['is_banned'] == true).length,
    };
  }

  Future<List<PostModel>> posts({String? status}) async {
    await requireAdmin();
    dynamic request = _client
        .from(DbTables.posts)
        .select(DbSelects.postWithImagesAndProfile);
    if (status != null) request = request.eq('status', status);
    final rows = await request.order('created_at', ascending: false);
    return rows
        .map<PostModel>(
          (row) => PostModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<ReportModel>> reports() async {
    await requireAdmin();
    final rows = await _client
        .from(DbTables.reports)
        .select()
        .order('created_at', ascending: false);
    return rows
        .map<ReportModel>(
          (row) => ReportModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<ProfileModel>> users() async {
    await requireAdmin();
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .order('created_at', ascending: false);
    return rows
        .map<ProfileModel>(
          (row) => ProfileModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> updatePostStatus(String postId, String status) async {
    await requireAdmin();
    final post = await _client
        .from(DbTables.posts)
        .select('user_id')
        .eq('id', postId)
        .single();
    await _client
        .from(DbTables.posts)
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
    final type = switch (status) {
      DbValues.approved => 'post_approved',
      DbValues.rejected => 'post_rejected',
      DbValues.returned => 'post_returned',
      _ => 'admin_notice',
    };
    final title = DbValues.notificationLabels[type] ?? 'ئاگادارکردنەوە';
    await _client.from(DbTables.notifications).insert({
      'user_id': post['user_id'],
      'title': title,
      'body': title,
      'type': type,
      'related_post_id': postId,
    });
  }

  Future<void> deletePost(String postId) async {
    await requireAdmin();
    await _client.from(DbTables.posts).delete().eq('id', postId);
  }

  Future<void> resolveReport(String reportId) async {
    await requireAdmin();
    await _client
        .from(DbTables.reports)
        .update({'status': 'resolved'})
        .eq('id', reportId);
  }

  Future<void> banUser(String userId, bool banned) async {
    await requireAdmin();
    await _client
        .from(DbTables.profiles)
        .update({
          'is_banned': banned,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
  }) async {
    await requireAdmin();
    final users = await _client
        .from(DbTables.profiles)
        .select('id')
        .eq('is_banned', false);
    final payload = users
        .map<Map<String, dynamic>>(
          (row) => {
            'user_id': row['id'],
            'title': title,
            'body': body,
            'type': 'admin_notice',
          },
        )
        .toList();
    if (payload.isNotEmpty) {
      await _client.from(DbTables.notifications).insert(payload);
    }
  }
}
