/// Authorisation level of a profile.
///
/// Note this mirrors the database only for display and client-side gating; the
/// authoritative check lives in Supabase row-level security policies.
enum UserRole {
  user('user', 'بەکارهێنەر'),
  moderator('moderator', 'چاودێر'),
  admin('admin', 'بەڕێوەبەر');

  const UserRole(this.wire, this.label);

  final String wire;
  final String label;

  static const fallback = UserRole.user;

  static UserRole parse(Object? value) {
    if (value == null) return fallback;
    final text = value.toString();
    for (final role in values) {
      if (role.wire == text) return role;
    }
    return fallback;
  }

  /// Whether this role may reach the moderation area.
  bool get canModerate => this == admin || this == moderator;
}
