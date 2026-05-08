class UserModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final String preferredLanguage;
  final String region;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.preferredLanguage = 'en',
    this.region = 'US',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      region: json['region'] as String? ?? 'US',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'preferred_language': preferredLanguage,
      'region': region,
      'created_at': createdAt.toIso8601String(),
    };
  }
}