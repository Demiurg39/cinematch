# Cinematch Phase 7: Friends System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to add friends, send requests, accept/reject. Friends list with online status. Block functionality.

**Architecture:** Friends stored in `friendships` table with status (pending/accepted/blocked). Supabase Realtime for presence.

**Tech Stack:** flutter_riverpod, Supabase Realtime, Supabase Postgres

---

## File Structure

```
lib/features/friends/
├── domain/
│   └── friendship_model.dart     # Friend request model
├── data/
│   └── friends_repository.dart   # Friend CRUD
└── presentation/
    ├── friends_screen.dart        # Friends list
    ├── add_friend_screen.dart     # Search/add friend
    └── providers/
        ├── friends_provider.dart
        └── friend_requests_provider.dart
```

---

## Tasks

### Task 1: Friendship Model

**Files:**
- Create: `lib/features/friends/domain/friendship_model.dart`

- [ ] **Step 1: Create friendship_model.dart**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/friends/domain/friendship_model.dart && git commit -m "feat: add FriendshipModel"
```

---

### Task 2: Friends Repository

**Files:**
- Create: `lib/features/friends/data/friends_repository.dart`

- [ ] **Step 1: Create friends_repository.dart**

```dart
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
      'friend_username': username,
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
    return response.map((json) => FriendshipModel.fromJson({...json, 'current_user_id': userId})).toList();
  }

  Future<List<FriendshipModel>> getPendingRequests() async {
    final userId = currentUserId!;
    final response = await _client.from('friendships').select()
        .eq('friend_id', userId).eq('status', 'pending');
    return response.map((json) => FriendshipModel.fromJson({...json, 'current_user_id': userId})).toList();
  }

  Stream<List<FriendshipModel>> watchFriends() {
    final userId = currentUserId!;
    return _client.from('friendships').stream(primaryKey: ['id'])
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted')
        .map((data) => data.map((json) => FriendshipModel.fromJson({...json, 'current_user_id': userId})).toList());
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/friends/data/friends_repository.dart && git commit -m "feat: add FriendsRepository"
```

---

### Task 3: Friends Providers

**Files:**
- Create: `lib/features/friends/presentation/providers/friends_provider.dart`
- Create: `lib/features/friends/presentation/providers/friend_requests_provider.dart`

- [ ] **Step 1: Create friends_provider.dart**

```dart
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
```

- [ ] **Step 2: Create friend_requests_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/friends_repository.dart';
import '../../domain/friendship_model.dart';

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
```

- [ ] **Step 3: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/features/friends/ && git commit -m "feat: add friends providers"
```

---

### Task 4: Friends Screens

**Files:**
- Create: `lib/features/friends/presentation/friends_screen.dart`
- Create: `lib/features/friends/presentation/add_friend_screen.dart`

- [ ] **Step 1: Create friends_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/friends_provider.dart';
import '../providers/friend_requests_provider.dart';
import '../../domain/friendship_model.dart';
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
          // Pending requests section
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
          // Friends list
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
```

- [ ] **Step 2: Create add_friend_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/friends_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter username',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(friendsNotifierProvider.notifier).sendRequest(_usernameController.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/friends/presentation/friends_screen.dart lib/features/friends/presentation/add_friend_screen.dart && git commit -m "feat: add FriendsScreen and AddFriendScreen"
```

---

### Task 5: Friends Tests

**Files:**
- Create: `test/friends/friendship_model_test.dart`

- [ ] **Step 1: Create friendship_model_test.dart**

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add test/friends/friendship_model_test.dart && git commit -m "test: add FriendshipModel tests"
```

---

## Self-Review

- [x] FriendshipModel with FriendshipStatus enum
- [x] FriendsRepository with CRUD + Realtime watch
- [x] FriendsNotifier + FriendRequestsNotifier
- [x] FriendsScreen with requests and list
- [x] AddFriendScreen
- [x] Tests for FriendshipModel
- [ ] Next: Phase 8 ML Recommendations

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-7-friends.md`**
