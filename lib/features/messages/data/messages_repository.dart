import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/data/profile_guard.dart';
import '../../../core/domain/notification_type.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/json.dart';
import '../../../core/utils/postgrest_filter.dart' as filters;
import '../../../shared/models/message_model.dart';

class MessagesRepository {
  MessagesRepository(this._client, this._images, this._profiles);

  final SupabaseClient _client;
  final ImageUploadService _images;
  final ProfileGuard _profiles;

  Future<List<ConversationModel>> conversations() {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final id = filters.quote(profile.id);
      final rows = await _client
          .from(DbTables.conversations)
          .select()
          .or(filters.or(['user_one_id.eq.$id', 'user_two_id.eq.$id']))
          .order('last_message_at', ascending: false);
      return _parseConversations(rows);
    });
  }

  Future<ConversationModel> conversationById(String id) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final row = await _client
          .from(DbTables.conversations)
          .select()
          .eq('id', id)
          .single();
      final conversation = ConversationModel.fromJson(row);
      // RLS already restricts the row, but checking here turns a silent empty
      // thread into an explicit, translatable error.
      if (!conversation.includes(profile.id)) {
        throw const PermissionFailure();
      }
      return conversation;
    });
  }

  /// Returns the existing thread between the caller and [otherUserId] about
  /// [postId], creating one if this is their first contact.
  Future<ConversationModel> createOrOpen({
    required String postId,
    required String otherUserId,
  }) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      if (profile.id == otherUserId) {
        throw const ValidationFailure('ناتوانیت نامە بۆ خۆت بنێریت');
      }

      final mine = filters.quote(profile.id);
      final theirs = filters.quote(otherUserId);
      final existing = await _client
          .from(DbTables.conversations)
          .select()
          .eq('post_id', postId)
          .or(
            filters.or([
              filters.andGroup([
                'user_one_id.eq.$mine',
                'user_two_id.eq.$theirs',
              ]),
              filters.andGroup([
                'user_one_id.eq.$theirs',
                'user_two_id.eq.$mine',
              ]),
            ]),
          )
          .limit(1);
      if (existing.isNotEmpty) {
        return ConversationModel.fromJson(existing.first);
      }

      final row = await _client
          .from(DbTables.conversations)
          .insert({
            'post_id': postId,
            'user_one_id': profile.id,
            'user_two_id': otherUserId,
            'last_message_at': DateTime.now().toUtcIso(),
          })
          .select()
          .single();
      return ConversationModel.fromJson(row);
    });
  }

  Future<List<MessageModel>> messages(String conversationId) {
    return guardFailures(() async {
      final rows = await _client
          .from(DbTables.messages)
          .select(DbSelects.messageWithSender)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return _parseMessages(rows);
    });
  }

  /// Live message feed for a thread.
  ///
  /// Realtime rows do not carry the joined sender profile, so bubbles are keyed
  /// off `sender_id` rather than the embedded profile.
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _client
        .from(DbTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(_parseMessages);
  }

  Future<void> sendMessage({
    required ConversationModel conversation,
    required String body,
    XFile? image,
  }) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      final text = body.trim();
      if (text.isEmpty && image == null) {
        throw const ValidationFailure('تکایە نامەیەک بنووسە');
      }
      await _assertHourlyQuota(profile.id);

      final receiverId = conversation.otherUserId(profile.id);
      String? imageUrl;
      if (image != null) {
        final path = await _images.uploadPostImage(
          file: image,
          postId: conversation.postId,
        );
        imageUrl = _images.publicUrl(path);
      }

      await _client.from(DbTables.messages).insert({
        'conversation_id': conversation.id,
        'sender_id': profile.id,
        'receiver_id': receiverId,
        'post_id': conversation.postId,
        'message': text,
        'image_url': imageUrl,
      });

      final preview = text.isEmpty ? 'وێنە' : text;
      // The thread summary and the recipient's notification are follow-ups to a
      // message that is already delivered. Failing them would show the sender an
      // error for a message the recipient can see, so they are best-effort.
      await _bestEffort(() async {
        await _client
            .from(DbTables.conversations)
            .update({
              'last_message': preview,
              'last_message_at': DateTime.now().toUtcIso(),
            })
            .eq('id', conversation.id);
      });
      await _bestEffort(() async {
        await _client.from(DbTables.notifications).insert({
          'user_id': receiverId,
          'title': NotificationType.newMessage.label,
          'body': text.isEmpty ? 'وێنەیەک بۆ تۆ نێردرا' : text,
          'type': NotificationType.newMessage.wire,
          'related_post_id': conversation.postId,
        });
      });
    });
  }

  Future<void> markRead(String conversationId) {
    return guardFailures(() async {
      final profile = await _profiles.require();
      await _client
          .from(DbTables.messages)
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', profile.id)
          .eq('is_read', false);
    });
  }

  Future<void> _assertHourlyQuota(String profileId) async {
    final since = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final recent = await _client
        .from(DbTables.messages)
        .select('id')
        .eq('sender_id', profileId)
        .gte('created_at', since.toIso8601String());
    if (recent.length >= AppLimits.maxMessagesPerHour) {
      throw const ValidationFailure(
        'زۆر نامەت ناردووە، تکایە دواتر هەوڵبدەرەوە',
      );
    }
  }

  static Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Deliberately ignored; the caller documents why at each call site.
    }
  }

  List<ConversationModel> _parseConversations(List<dynamic> rows) {
    return rows
        .map(
          (row) =>
              ConversationModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  List<MessageModel> _parseMessages(List<dynamic> rows) {
    return rows
        .map(
          (row) => MessageModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}
