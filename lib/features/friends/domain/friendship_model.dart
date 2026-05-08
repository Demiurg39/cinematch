enum FriendshipStatus { pending, accepted, blocked }

class FriendshipModel {
  final String id;
  final String friendId;
  final String friendUsername;
  final String? friendAvatarUrl;
  final FriendshipStatus status;
  final bool isIncoming;
  final DateTime createdAt;

  const FriendshipModel({
    required this.id,
    required this.friendId,
    required this.friendUsername,
    this.friendAvatarUrl,
    required this.status,
    required this.isIncoming,
    required this.createdAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'] as String;
    final currentUserId = json['current_user_id'] as String;
    final isIncoming = userId != currentUserId;

    return FriendshipModel(
      id: json['id'] as String,
      friendId: isIncoming ? userId : (json['friend_id'] as String),
      friendUsername: json['friend_username'] as String? ?? 'Unknown',
      friendAvatarUrl: json['friend_avatar_url'] as String?,
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      isIncoming: isIncoming,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
