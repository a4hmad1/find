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

  final String id;
  final String reporterId;
  final String? postId;
  final String? reportedUserId;
  final String reason;
  final String? description;
  final String status;
  final DateTime? createdAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      reporterId: json['reporter_id']?.toString() ?? '',
      postId: json['post_id']?.toString(),
      reportedUserId: json['reported_user_id']?.toString(),
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
