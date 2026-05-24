import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../friends/presentation/providers/friends_provider.dart';
import '../../data/rooms_repository.dart';
import '../providers/rooms_provider.dart';

class InviteFriendsSheet extends ConsumerWidget {
  final String roomId;

  const InviteFriendsSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final friendsAsync = ref.watch(friendsNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Invite Friends', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: friendsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (friends) {
                    if (friends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('No friends to invite', style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: friends.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              friend.friendUsername[0].toUpperCase(),
                              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                          title: Text(friend.friendUsername),
                          trailing: FilledButton.tonal(
                            onPressed: () async {
                              final repo = ref.read(roomsRepositoryProvider);
                              await repo.joinRoom(roomId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Invited ${friend.friendUsername}')),
                                );
                              }
                            },
                            child: const Text('Invite'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
