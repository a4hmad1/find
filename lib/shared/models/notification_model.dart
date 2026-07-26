import '../../core/domain/notification_type.dart';
import '../../core/utils/json.dart';

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

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json.asString('id'),
      userId: json.asString('user_id'),
      title: json.asString('title'),
      body: json.asString('body'),
      type: NotificationType.parse(json['type']),
      relatedPostId: json.asStringOrNull('related_post_id'),
      isRead: json.asBool('is_read'),
      createdAt: json.asDateOrNull('created_at'),
    );
  }

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedPostId;
  final bool isRead;
  final DateTime? createdAt;

  /// A title to render, falling back to the type's default when the row was
  /// written without one.
  String get resolvedTitle => title.isNotEmpty ? title : type.label;

  bool get opensPost => relatedPostId != null && relatedPostId!.isNotEmpty;
}
