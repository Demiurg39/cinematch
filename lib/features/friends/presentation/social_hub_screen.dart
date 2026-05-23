import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../partners/presentation/providers/partners_provider.dart';
import '../../partners/presentation/widgets/partner_dashboard.dart';
import '../../partners/presentation/add_partner_screen.dart';
import 'providers/friends_provider.dart';
import 'providers/friend_requests_provider.dart';
import 'add_friend_screen.dart';

class SocialHubScreen extends ConsumerWidget {
  const SocialHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final partnersAsync = ref.watch(partnersNotifierProvider);
    final friendsAsync = ref.watch(friendsNotifierProvider);
    final requestsAsync = ref.watch(friendRequestsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Friend',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Add Partner',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPartnerScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Active Partner Section ──
          partnersAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 32),
                    const SizedBox(height: 8),
                    Text('Could not load partners', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            data: (partners) {
              final active = partners.where((p) => p.status.name == 'active').firstOrNull;
              final pending = partners.where((p) => p.status.name == 'pending').toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active partner
                  if (active != null) ...[
                    Row(
                      children: [
                        Text('Active Partner', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Icon(Icons.favorite, color: theme.colorScheme.error, size: 18),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PartnerDashboard(partner: active),
                    const Divider(height: 32),
                  ],

                  // Pending partner requests
                  if (pending.isNotEmpty) ...[
                    Text('Partner Requests', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...pending.map((p) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.tertiaryContainer,
                          child: Text(p.partnerUsername[0].toUpperCase()),
                        ),
                        title: Text(p.partnerUsername),
                        subtitle: const Text('Wants to be your partner'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => ref.read(partnersNotifierProvider.notifier).accept(p.partnerId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => ref.read(partnersNotifierProvider.notifier).reject(p.partnerId),
                            ),
                          ],
                        ),
                      ),
                    )),
                    if (pending.isNotEmpty) const Divider(height: 24),
                  ],
                ],
              );
            },
          ),

          // ── Friend Requests Section ──
          requestsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (requests) {
              if (requests.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Friend Requests', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...requests.map((req) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(req.friendUsername[0].toUpperCase()),
                      ),
                      title: Text(req.friendUsername),
                      subtitle: const Text('Wants to be friends'),
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
                    ),
                  )),
                  const Divider(height: 24),
                ],
              );
            },
          ),

          // ── Friends List Section ──
          Text('Friends', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (friends) {
              if (friends.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('No friends yet', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text('Add friends to see their activity here',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          friend.friendUsername[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(friend.friendUsername),
                      subtitle: const Text('Friend'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'promote') {
                            ref.read(partnersNotifierProvider.notifier).sendRequest(friend.friendUsername);
                          } else if (value == 'remove') {
                            ref.read(friendsNotifierProvider.notifier).remove(friend.friendId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'promote',
                            child: ListTile(
                              leading: Icon(Icons.favorite, color: Colors.red),
                              title: Text('Promote to Partner'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: ListTile(
                              leading: Icon(Icons.person_remove, color: Colors.red),
                              title: Text('Remove Friend'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}