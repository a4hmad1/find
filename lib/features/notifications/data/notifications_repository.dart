import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/models/profile_model.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Future<ProfileModel> _profile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) throw const AppException('تکایە بچۆ ژوورەوە');
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authId)
        .limit(1);
    if (rows.isEmpty) throw const AppException('هەژمارەکە نەدۆزرایەوە');
    return ProfileModel.fromJson(rows.first);
  }

  Future<List<AppNotificationModel>> list() async {
    final profile = await _profile();
    final rows = await _client
        .from(DbTables.notifications)
        .select()
        .eq('user_id', profile.id)
        .order('created_at', ascending: false);
    return rows
        .map<AppNotificationModel>(
          (row) =>
              AppNotificationModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> markRead(String id) async {
    await _client
        .from(DbTables.notifications)
        .update({'is_read': true})
        .eq('id', id);
  }
}
