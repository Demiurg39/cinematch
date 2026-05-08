import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/friendship_model.dart';
import 'friends_provider.dart';

part 'friend_requests_provider.g.dart';

@riverpod
class FriendRequestsNotifier extends _$FriendRequestsNotifier {
  @override
  Future<List<FriendshipModel>> build() async {
    return ref.read(friendsRepositoryProvider).getPendingRequests();
  }

  Future<void> accept(String friendshipId) async {
    await ref.read(friendsRepositoryProvider).acceptFriendRequest(friendshipId);
    ref.invalidateSelf();
  }

  Future<void> reject(String friendshipId) async {
    await ref.read(friendsRepositoryProvider).rejectFriendRequest(friendshipId);
    ref.invalidateSelf();
  }
}
