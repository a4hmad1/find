class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.relatedPostId,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedPostId;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      relatedPostId: json['related_post_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
