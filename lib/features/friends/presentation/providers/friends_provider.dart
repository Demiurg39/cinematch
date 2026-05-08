import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/friends_repository.dart';
import '../../domain/friendship_model.dart';

part 'friends_provider.g.dart';

@riverpod
FriendsRepository friendsRepository(FriendsRepositoryRef ref) {
  return FriendsRepository();
}

@riverpod
class FriendsNotifier extends _$FriendsNotifier {
  @override
  Stream<List<FriendshipModel>> build() {
    return ref.read(friendsRepositoryProvider).watchFriends();
  }

  Future<void> sendRequest(String username) async {
    await ref.read(friendsRepositoryProvider).sendFriendRequest(username);
  }

  Future<void> remove(String friendId) async {
    await ref.read(friendsRepositoryProvider).removeFriend(friendId);
  }
}
