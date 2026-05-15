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

  final String id;
  final String postId;
  final String userOneId;
  final String userTwoId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userOneId: json['user_one_id']?.toString() ?? '',
      userTwoId: json['user_two_id']?.toString() ?? '',
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: DateTime.tryParse(
        json['last_message_at']?.toString() ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String otherUserId(String currentUserId) {
    return userOneId == currentUserId ? userTwoId : userOneId;
  }
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

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profiles'] ?? json['sender'];
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      sender: profileJson is Map
          ? ProfileModel.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }
}
