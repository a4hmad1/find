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

  final String id;
  final String authUserId;
  final String githubId;
  final String githubUsername;
  final String displayName;
  final String avatarUrl;
  final String role;
  final bool isBanned;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin' || role == 'moderator';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      authUserId: json['auth_user_id']?.toString() ?? '',
      githubId: json['github_id']?.toString() ?? '',
      githubUsername: json['github_username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'user',
      isBanned: json['is_banned'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_user_id': authUserId,
      'github_id': githubId,
      'github_username': githubUsername,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'email': email,
      'role': role,
      'is_banned': isBanned,
    };
  }
}
