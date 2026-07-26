import '../../core/domain/notification_type.dart';
import '../../core/utils/json.dart';

class ReportModel {
  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.reason,
    required this.status,
    this.postId,
    this.reportedUserId,
    this.description,
    this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json.asString('id'),
      reporterId: json.asString('reporter_id'),
      postId: json.asStringOrNull('post_id'),
      reportedUserId: json.asStringOrNull('reported_user_id'),
      reason: json.asString('reason'),
      description: json.asStringOrNull('description'),
      status: ReportStatus.parse(json['status']),
      createdAt: json.asDateOrNull('created_at'),
    );
  }

  final String id;
  final String reporterId;
  final String? postId;
  final String? reportedUserId;
  final String reason;
  final String? description;
  final ReportStatus status;
  final DateTime? createdAt;

  bool get isOpen => status == ReportStatus.pending;
}
