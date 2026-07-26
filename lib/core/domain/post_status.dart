/// Moderation and lifecycle state of a post.
///
/// [wire] is the value stored in the `posts.status` column; [label] is the
/// Kurdish text shown to users.
enum PostStatus {
  pending('pending', 'چاوەڕوانە'),
  approved('approved', 'پشتڕاستکراوە'),
  returned('returned', 'گەڕێنراوەتەوە'),
  closed('closed', 'داخراوە'),
  rejected('rejected', 'پەسەند نەکرا');

  const PostStatus(this.wire, this.label);

  final String wire;
  final String label;

  static PostStatus? tryParse(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    for (final status in values) {
      if (status.wire == text) return status;
    }
    return null;
  }

  /// Statuses a signed-out visitor is allowed to browse.
  static const publiclyVisible = <PostStatus>{approved, returned, closed};

  /// Statuses an owner or moderator may select from in the UI.
  static const selectable = <PostStatus>[pending, approved, returned, closed];

  /// A post in one of these states no longer accepts contact requests.
  bool get isTerminal => this == closed || this == returned;
}
