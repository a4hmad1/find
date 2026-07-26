import '../../core/utils/json.dart';
import 'profile_model.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.postId,
    required this.userOneId,
    required this.userTwoId,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json.asString('id'),
      postId: json.asString('post_id'),
      userOneId: json.asString('user_one_id'),
      userTwoId: json.asString('user_two_id'),
      lastMessage: json.asStringOrNull('last_message'),
      lastMessageAt: json.asDateOrNull('last_message_at'),
      createdAt: json.asDateOrNull('created_at'),
    );
  }

  final String id;
  final String postId;
  final String userOneId;
  final String userTwoId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  /// The participant who is not [currentUserId].
  String otherUserId(String currentUserId) {
    return userOneId == currentUserId ? userTwoId : userOneId;
  }

  bool includes(String profileId) =>
      userOneId == profileId || userTwoId == profileId;
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.postId,
    required this.message,
    required this.isRead,
    this.imageUrl,
    this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] ?? json['sender'];
    return MessageModel(
      id: json.asString('id'),
      conversationId: json.asString('conversation_id'),
      senderId: json.asString('sender_id'),
      receiverId: json.asString('receiver_id'),
      postId: json.asString('post_id'),
      message: json.asString('message'),
      imageUrl: json.asStringOrNull('image_url'),
      isRead: json.asBool('is_read'),
      createdAt: json.asDateOrNull('created_at'),
      sender: profileJson is Map
          ? ProfileModel.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String postId;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime? createdAt;
  final ProfileModel? sender;

  bool get hasImage => (imageUrl ?? '').isNotEmpty;
  bool get hasText => message.isNotEmpty;
}
