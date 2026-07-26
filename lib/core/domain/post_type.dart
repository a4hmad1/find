/// The nature of a post: an item that was found, lost, or stolen.
///
/// [wire] is the value stored in the `posts.post_type` column; [label] is the
/// Kurdish text shown to users. Parsing is tolerant so that a value added to
/// the database ahead of the client does not crash decoding.
enum PostType {
  found('found', 'دۆزراوە'),
  lost('lost', 'ونبووە'),
  stolen('stolen', 'دزراوە');

  const PostType(this.wire, this.label);

  final String wire;
  final String label;

  static PostType? tryParse(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    for (final type in values) {
      if (type.wire == text) return type;
    }
    return null;
  }

  /// The counterpart type used when looking for candidate matches: someone who
  /// lost an item wants to see found items, and vice versa.
  PostType get opposite => switch (this) {
    PostType.lost => PostType.found,
    PostType.found => PostType.lost,
    PostType.stolen => PostType.found,
  };
}
