import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/friends_provider.dart';
import 'providers/friend_requests_provider.dart';
import '../domain/friendship_model.dart';
import 'add_friend_screen.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsNotifierProvider);
    final requestsAsync = ref.watch(friendRequestsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Column(
        children: [
          requestsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Friend Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ...requests.map((req) => ListTile(
                    leading: CircleAvatar(child: Text(req.friendUsername[0].toUpperCase())),
                    title: Text(req.friendUsername),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => ref.read(friendRequestsNotifierProvider.notifier).accept(req.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => ref.read(friendRequestsNotifierProvider.notifier).reject(req.id),
                        ),
                      ],
                    ),
                  )),
                ],
              );
            },
          ),
          Expanded(
            child: friendsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (friends) {
                if (friends.isEmpty) {
                  return const Center(child: Text('No friends yet'));
                }
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(friend.friendUsername[0].toUpperCase()),
                      ),
                      title: Text(friend.friendUsername),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () => ref.read(friendsNotifierProvider.notifier).remove(friend.friendId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFriendScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
