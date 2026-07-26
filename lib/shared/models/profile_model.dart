import '../../core/domain/user_role.dart';
import '../../core/utils/json.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.authUserId,
    required this.githubId,
    required this.githubUsername,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.isBanned,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json.asString('id'),
      authUserId: json.asString('auth_user_id'),
      githubId: json.asString('github_id'),
      githubUsername: json.asString('github_username'),
      displayName: json.asString('display_name'),
      avatarUrl: json.asString('avatar_url'),
      email: json.asStringOrNull('email'),
      role: UserRole.parse(json['role']),
      isBanned: json.asBool('is_banned'),
      createdAt: json.asDateOrNull('created_at'),
      updatedAt: json.asDateOrNull('updated_at'),
    );
  }

  final String id;
  final String authUserId;
  final String githubId;
  final String githubUsername;
  final String displayName;
  final String avatarUrl;
  final UserRole role;
  final bool isBanned;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.canModerate;

  /// A non-empty name to render, since `display_name` can be blank for GitHub
  /// accounts that never set one.
  String get resolvedDisplayName =>
      displayName.isNotEmpty ? displayName : githubUsername;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'github_id': githubId,
      'github_username': githubUsername,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'email': email,
      'role': role.wire,
      'is_banned': isBanned,
    };
  }
}
