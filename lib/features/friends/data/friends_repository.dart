import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/friendship_model.dart';

class FriendsRepository {
  final SupabaseClient _client;
  FriendsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<FriendshipModel> sendFriendRequest(String username) async {
    final userId = currentUserId!;

    final friend = await _client.from('users').select().eq('username', username).maybeSingle();
    if (friend == null) throw Exception('User not found');
    if (friend['id'] == userId) throw Exception('Cannot add yourself');

    final response = await _client.from('friendships').insert({
      'user_id': userId,
      'friend_id': friend['id'],
      'status': 'pending',
    }).select().single();

    return FriendshipModel.fromJson({...response, 'current_user_id': userId});
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _client.from('friendships').update({'status': 'accepted'}).eq('id', friendshipId);
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  Future<void> removeFriend(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('friendships').delete()
        .or('and(user_id.eq.$uid,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$uid)');
  }

  Future<void> blockUser(String friendId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('friendships').update({'status': 'blocked'})
        .or('and(user_id.eq.$uid,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$uid)');
  }

  Future<List<FriendshipModel>> getFriends() async {
    final userId = currentUserId!;
    final response = await _client.from('friendships').select()
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted');

    // Fetch usernames for friends one by one
    final result = <FriendshipModel>[];
    for (final json in response) {
      final friendId = friendIdKey(json, userId);
      String friendUsername = 'Unknown';
      try {
        final user = await _client.from('users').select('username').eq('id', friendId).maybeSingle();
        friendUsername = (user?['username'] as String?) ?? 'Unknown';
      } catch (_) {}

      result.add(FriendshipModel.fromJson({
        ...json,
        'current_user_id': userId,
        'friend_username': friendUsername,
      }));
    }
    return result;
  }

  Future<List<FriendshipModel>> getPendingRequests() async {
    final userId = currentUserId!;
    final response = await _client.from('friendships').select()
        .eq('friend_id', userId).eq('status', 'pending');

    if (response.isEmpty) return [];

    // Fetch usernames for requesters one by one
    final result = <FriendshipModel>[];
    for (final json in response) {
      final requesterId = json['user_id'] as String;
      String friendUsername = 'Unknown';
      try {
        final user = await _client.from('users').select('username').eq('id', requesterId).maybeSingle();
        friendUsername = (user?['username'] as String?) ?? 'Unknown';
      } catch (_) {}

      result.add(FriendshipModel.fromJson({
        ...json,
        'current_user_id': userId,
        'friend_username': friendUsername,
      }));
    }
    return result;
  }

  String friendIdKey(Map<String, dynamic> json, String currentUserId) {
    return json['user_id'] == currentUserId ? json['friend_id'] as String : json['user_id'] as String;
  }

  Stream<List<FriendshipModel>> watchFriends() {
    final userId = currentUserId!;
    return _client.from('friendships').stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final friendsData = data
              .where((json) => json['user_id'] == userId || json['friend_id'] == userId)
              .where((json) => json['status'] == 'accepted')
              .toList();

          final result = <FriendshipModel>[];
          for (final json in friendsData) {
            final friendId = friendIdKey(json, userId);
            String friendUsername = 'Unknown';
            try {
              final user = await _client.from('users').select('username').eq('id', friendId).maybeSingle();
              friendUsername = (user?['username'] as String?) ?? 'Unknown';
            } catch (_) {}

            result.add(FriendshipModel.fromJson({
              ...json,
              'current_user_id': userId,
              'friend_username': friendUsername,
            }));
          }
          return result;
        });
  }
}
