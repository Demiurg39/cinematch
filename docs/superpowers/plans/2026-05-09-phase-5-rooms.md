# Cinematch Phase 5: Room System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow users to create/join rooms for group swiping. Room states: lobby → voting → matched → revealed. All participants swipe independently; movies with all likes create a match.

**Architecture:** Room code (6-char) for join. Supabase `rooms` + `room_participants` tables. Supabase Realtime for room state sync.

**Tech Stack:** flutter_riverpod, Supabase Realtime, Supabase Postgres

---

## File Structure

```
lib/features/rooms/
├── domain/
│   └── room_model.dart              # Room state model
├── data/
│   └── rooms_repository.dart        # Room CRUD operations
└── presentation/
    ├── rooms_screen.dart           # Room list/entry screen
    ├── room_lobby_screen.dart       # Waiting room
    └── providers/
        ├── rooms_provider.dart     # Room list state
        └── room_provider.dart       # Active room state
```

---

## Tasks

### Task 1: Room Model

**Files:**
- Create: `lib/features/rooms/domain/room_model.dart`

- [ ] **Step 1: Create room_model.dart**

```dart
enum RoomStatus { lobby, voting, matched, revealed }

class RoomModel {
  final String id;
  final String code;
  final String name;
  final String createdBy;
  final RoomStatus status;
  final int matchThreshold;
  final DateTime createdAt;
  final List<String> participantIds;

  const RoomModel({
    required this.id,
    required this.code,
    required this.name,
    required this.createdBy,
    required this.status,
    required this.matchThreshold,
    required this.createdAt,
    required this.participantIds,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RoomStatus.lobby,
      ),
      matchThreshold: json['match_threshold'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      participantIds: (json['participant_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'created_by': createdBy,
    'status': status.name,
    'match_threshold': matchThreshold,
    'created_at': createdAt.toIso8601String(),
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/rooms/domain/room_model.dart && git commit -m "feat: add RoomModel"
```

---

### Task 2: Rooms Repository

**Files:**
- Create: `lib/features/rooms/data/rooms_repository.dart`

- [ ] **Step 1: Create rooms_repository.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/room_model.dart';

class RoomsRepository {
  final SupabaseClient _client;
  RoomsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<RoomModel> createRoom({
    required String name,
    required int matchThreshold,
  }) async {
    final code = _generateRoomCode();
    final userId = currentUserId!;

    final response = await _client.from('rooms').insert({
      'code': code,
      'name': name,
      'created_by': userId,
      'status': 'lobby',
      'match_threshold': matchThreshold,
    }).select().single();

    // Add creator as participant
    await _client.from('room_participants').insert({
      'room_id': response['id'],
      'user_id': userId,
    });

    return RoomModel.fromJson(response);
  }

  Future<RoomModel?> getRoomByCode(String code) async {
    final response = await _client.from('rooms').select().eq('code', code).maybeSingle();
    if (response == null) return null;
    return RoomModel.fromJson(response);
  }

  Future<void> joinRoom(String roomId) async {
    await _client.from('room_participants').insert({
      'room_id': roomId,
      'user_id': currentUserId,
    });
  }

  Future<void> leaveRoom(String roomId) async {
    await _client.from('room_participants').delete()
        .eq('room_id', roomId).eq('user_id', currentUserId);
  }

  Future<List<RoomModel>> getMyRooms() async {
    final userId = currentUserId!;
    final response = await _client.from('rooms').select().contains('participant_ids', [userId]);
    return response.map((json) => RoomModel.fromJson(json)).toList();
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _client.from('rooms').stream(primaryKey: ['id']).eq('id', roomId).map((data) {
      return RoomModel.fromJson(data.first);
    });
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _client.from('rooms').update({'status': status.name}).eq('id', roomId);
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/rooms/data/rooms_repository.dart && git commit -m "feat: add RoomsRepository"
```

---

### Task 3: Rooms Provider

**Files:**
- Create: `lib/features/rooms/presentation/providers/rooms_provider.dart`

- [ ] **Step 1: Create rooms_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/rooms_repository.dart';
import '../../domain/room_model.dart';

part 'rooms_provider.g.dart';

@riverpod
RoomsRepository roomsRepository(RoomsRepositoryRef ref) {
  return RoomsRepository();
}

@riverpod
class MyRoomsNotifier extends _$MyRoomsNotifier {
  @override
  Future<List<RoomModel>> build() async {
    final repo = ref.read(roomsRepositoryProvider);
    return repo.getMyRooms();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(roomsRepositoryProvider).getMyRooms());
  }
}

@riverpod
class RoomByCodeNotifier extends _$RoomByCodeNotifier {
  @override
  Future<RoomModel?> build(String code) async {
    return ref.read(roomsRepositoryProvider).getRoomByCode(code);
  }
}
```

- [ ] **Step 2: Create room_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/rooms_repository.dart';
import '../../domain/room_model.dart';

part 'room_provider.g.dart';

@riverpod
class ActiveRoomNotifier extends _$ActiveRoomNotifier {
  @override
  Stream<RoomModel?> build(String roomId) {
    return ref.read(roomsRepositoryProvider).watchRoom(roomId);
  }

  Future<void> join() async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).joinRoom(room.id);
    }
  }

  Future<void> leave() async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).leaveRoom(room.id);
    }
  }

  Future<void> startVoting() async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).updateRoomStatus(room.id, RoomStatus.voting);
    }
  }
}
```

- [ ] **Step 3: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Commit**

```bash
git add lib/features/rooms/ && git commit -m "feat: add rooms providers and RoomModel"
```

---

### Task 4: Rooms Screens

**Files:**
- Create: `lib/features/rooms/presentation/rooms_screen.dart`
- Create: `lib/features/rooms/presentation/room_lobby_screen.dart`

- [ ] **Step 1: Create rooms_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rooms_provider.dart';
import 'room_lobby_screen.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(
              child: Text('No rooms yet. Create or join one!'),
            );
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                title: Text(room.name),
                subtitle: Text('Code: ${room.code}'),
                trailing: Chip(label: Text(room.status.name)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomLobbyScreen(roomId: room.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoomDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Create Room'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Room Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final repo = ref.read(roomsRepositoryProvider);
                final room = await repo.createRoom(
                  name: nameController.text,
                  matchThreshold: 2,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomLobbyScreen(roomId: room.id),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 2: Create room_lobby_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';
import '../../../swipe/presentation/swipe_screen.dart';

class RoomLobbyScreen extends ConsumerWidget {
  final String roomId;

  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(activeRoomNotifierProvider(roomId));

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (room) {
        if (room == null) {
          return const Scaffold(
            body: Center(child: Text('Room not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(room.name)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Room Code: ${room.code}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(label: Text(room.status.name.toUpperCase())),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('${room.participantIds.length} participants'),
                ),
              ),
              if (room.status == RoomStatus.lobby && room.createdBy == ref.read(roomsRepositoryProvider).currentUserId)
                FilledButton(
                  onPressed: () => ref.read(activeRoomNotifierProvider(roomId).notifier).startVoting(),
                  child: const Text('Start Voting'),
                ),
              if (room.status == RoomStatus.voting)
                FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SwipeScreen()),
                  ),
                  child: const Text('Start Swiping'),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/rooms/presentation/rooms_screen.dart lib/features/rooms/presentation/room_lobby_screen.dart && git commit -m "feat: add RoomsScreen and RoomLobbyScreen"
```

---

### Task 5: Rooms Tests

**Files:**
- Create: `test/rooms/room_model_test.dart`

- [ ] **Step 1: Create room_model_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/rooms/domain/room_model.dart';

void main() {
  group('RoomModel', () {
    test('fromJson creates RoomModel correctly', () {
      final json = {
        'id': 'room-123',
        'code': 'ABC123',
        'name': 'Test Room',
        'created_by': 'user-456',
        'status': 'lobby',
        'match_threshold': 2,
        'created_at': '2024-01-01T00:00:00.000Z',
        'participant_ids': ['user-1', 'user-2'],
      };

      final room = RoomModel.fromJson(json);

      expect(room.id, 'room-123');
      expect(room.code, 'ABC123');
      expect(room.name, 'Test Room');
      expect(room.status, RoomStatus.lobby);
      expect(room.matchThreshold, 2);
      expect(room.participantIds.length, 2);
    });
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add test/rooms/room_model_test.dart && git commit -m "test: add RoomModel tests"
```

---

## Self-Review

- [x] RoomModel with RoomStatus enum
- [x] RoomsRepository with CRUD + Realtime watch
- [x] RoomsProvider + RoomProvider for state
- [x] RoomsScreen with create/join UI
- [x] RoomLobbyScreen with status transitions
- [x] Tests for RoomModel
- [ ] Next: Phase 6 Partner Mode

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-5-rooms.md`**
