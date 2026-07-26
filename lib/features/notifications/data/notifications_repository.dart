import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/errors/app_failure.dart';
import '../../../shared/models/notification_model.dart';

class NotificationsRepository {
  NotificationsRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final ProfileGuard _profiles;

  Future<List<AppNotificationModel>> list() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final rows = await _client
          .from(DbTables.notifications)
          .select()
          .eq('user_id', profile.id)
          .order('created_at', ascending: false);
      return rows
          .map(
            (row) => AppNotificationModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    });
  }

  /// Number of unread notifications, for the badge on the home header.
  Future<int> unreadCount() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final rows = await _client
          .from(DbTables.notifications)
          .select('id')
          .eq('user_id', profile.id)
          .eq('is_read', false);
      return rows.length;
    });
  }

  Future<void> markRead(String id) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      // Scoping the update to the caller means a tampered id cannot flip
      // someone else's row, independently of the RLS policy.
      await _client
          .from(DbTables.notifications)
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', profile.id);
    });
  }

  Future<void> markAllRead() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client
          .from(DbTables.notifications)
          .update({'is_read': true})
          .eq('user_id', profile.id)
          .eq('is_read', false);
    });
  }
}
