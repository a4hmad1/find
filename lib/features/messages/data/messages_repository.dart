import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/profile_model.dart';

class MessagesRepository {
  MessagesRepository(this._client, this._images);

  final SupabaseClient _client;
  final ImageUploadService _images;

  Future<ProfileModel> _profile() async {
    final authId = _client.auth.currentUser?.id;
    if (authId == null) throw const AppException('تکایە بچۆ ژوورەوە');
    final rows = await _client
        .from(DbTables.profiles)
        .select(DbSelects.publicProfile)
        .eq('auth_user_id', authId)
        .limit(1);
    if (rows.isEmpty) throw const AppException('هەژمارەکە نەدۆزرایەوە');
    final profile = ProfileModel.fromJson(rows.first);
    if (profile.isBanned) throw const AppException('هەژمارەکەت ڕاگیراوە');
    return profile;
  }

  Future<List<ConversationModel>> conversations() async {
    final profile = await _profile();
    final rows = await _client
        .from(DbTables.conversations)
        .select()
        .or('user_one_id.eq.${profile.id},user_two_id.eq.${profile.id}')
        .order('last_message_at', ascending: false);
    return rows
        .map<ConversationModel>(
          (row) => ConversationModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<ConversationModel> conversationById(String id) async {
    await _profile();
    final row = await _client
        .from(DbTables.conversations)
        .select()
        .eq('id', id)
        .single();
    return ConversationModel.fromJson(row);
  }

  Future<ConversationModel> createOrOpen({
    required String postId,
    required String otherUserId,
  }) async {
    final profile = await _profile();
    if (profile.id == otherUserId) {
      throw const AppException('ناتوانیت نامە بۆ خۆت بنێریت');
    }
    final rows = await _client
        .from(DbTables.conversations)
        .select()
        .eq('post_id', postId)
        .or(
          'and(user_one_id.eq.${profile.id},user_two_id.eq.$otherUserId),and(user_one_id.eq.$otherUserId,user_two_id.eq.${profile.id})',
        )
        .limit(1);
    if (rows.isNotEmpty) return ConversationModel.fromJson(rows.first);

    final row = await _client
        .from(DbTables.conversations)
        .insert({
          'post_id': postId,
          'user_one_id': profile.id,
          'user_two_id': otherUserId,
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();
    return ConversationModel.fromJson(row);
  }

  Future<List<MessageModel>> messages(String conversationId) async {
    final rows = await _client
        .from(DbTables.messages)
        .select('*, profiles(${DbSelects.publicProfile})')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return rows
        .map<MessageModel>(
          (row) => MessageModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _client
        .from(DbTables.messages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) => MessageModel.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
        );
  }

  Future<void> sendMessage({
    required ConversationModel conversation,
    required String body,
    XFile? image,
  }) async {
    final profile = await _profile();
    final text = body.trim();
    if (text.isEmpty && image == null) {
      throw const AppException('تکایە نامەیەک بنووسە');
    }
    final oneHourAgo = DateTime.now().toUtc().subtract(
      const Duration(hours: 1),
    );
    final recentMessages = await _client
        .from(DbTables.messages)
        .select('id')
        .eq('sender_id', profile.id)
        .gte('created_at', oneHourAgo.toIso8601String());
    if (recentMessages.length >= 20) {
      throw const AppException('زۆر نامەت ناردووە، تکایە دواتر هەوڵبدەرەوە');
    }
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
    await _client
        .from(DbTables.conversations)
        .update({
          'last_message': text.isEmpty ? 'وێنە' : text,
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversation.id);
    await _client.from(DbTables.notifications).insert({
      'user_id': receiverId,
      'title': 'نامەیەکی نوێت هەیە',
      'body': text.isEmpty ? 'وێنەیەک بۆ تۆ نێردرا' : text,
      'type': 'new_message',
      'related_post_id': conversation.postId,
    });
  }

  Future<void> markRead(String conversationId) async {
    final profile = await _profile();
    await _client
        .from(DbTables.messages)
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('receiver_id', profile.id);
  }
}
