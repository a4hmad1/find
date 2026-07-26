/// Category of an in-app notification, used to pick an icon and a default title.
enum NotificationType {
  newMessage('new_message', 'نامەیەکی نوێت هەیە'),
  postApproved('post_approved', 'بابەتەکەت پشتڕاستکرایەوە'),
  postRejected('post_rejected', 'بابەتەکەت پەسەند نەکرا'),
  postReturned('post_returned', 'شتەکە گەڕێنراوەتەوە'),
  similarItem('similar_item', 'شتێکی هاوشێوە دۆزرایەوە'),
  adminNotice('admin_notice', 'ئاگادارکردنەوەی بەڕێوەبەر');

  const NotificationType(this.wire, this.label);

  final String wire;
  final String label;

  static const fallback = NotificationType.adminNotice;

  static NotificationType parse(Object? value) {
    if (value == null) return fallback;
    final text = value.toString();
    for (final type in values) {
      if (type.wire == text) return type;
    }
    return fallback;
  }
}

/// Lifecycle of an abuse report.
enum ReportStatus {
  pending('pending', 'چاوەڕوانە'),
  resolved('resolved', 'چارەسەرکراوە'),
  dismissed('dismissed', 'ڕەتکرایەوە');

  const ReportStatus(this.wire, this.label);

  final String wire;
  final String label;

  static const fallback = ReportStatus.pending;

  static ReportStatus parse(Object? value) {
    if (value == null) return fallback;
    final text = value.toString();
    for (final status in values) {
      if (status.wire == text) return status;
    }
    return fallback;
  }
}
