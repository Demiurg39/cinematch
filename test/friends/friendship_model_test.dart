import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/friends/domain/friendship_model.dart';

void main() {
  group('FriendshipModel', () {
    test('fromJson creates FriendshipModel for incoming request', () {
      final json = {
        'id': 'friend-123',
        'user_id': 'user-456',
        'friend_id': 'user-789',
        'friend_username': 'johndoe',
        'status': 'pending',
        'created_at': '2024-01-01T00:00:00.000Z',
        'current_user_id': 'user-789',
      };

      final friendship = FriendshipModel.fromJson(json);

      expect(friendship.id, 'friend-123');
      expect(friendship.friendId, 'user-456');
      expect(friendship.friendUsername, 'johndoe');
      expect(friendship.status, FriendshipStatus.pending);
      expect(friendship.isIncoming, true);
    });

    test('fromJson creates FriendshipModel for outgoing request', () {
      final json = {
        'id': 'friend-123',
        'user_id': 'user-456',
        'friend_id': 'user-789',
        'friend_username': 'johndoe',
        'status': 'accepted',
        'created_at': '2024-01-01T00:00:00.000Z',
        'current_user_id': 'user-456',
      };

      final friendship = FriendshipModel.fromJson(json);

      expect(friendship.id, 'friend-123');
      expect(friendship.friendId, 'user-789');
      expect(friendship.status, FriendshipStatus.accepted);
      expect(friendship.isIncoming, false);
    });
  });
}
