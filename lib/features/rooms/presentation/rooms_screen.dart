import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/rooms_provider.dart';
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
            return const Center(child: Text('No rooms yet. Create or join one!'));
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
                  MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: room.id)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          key: const ValueKey('create_room_fab'),
          onPressed: () => _showOptionsDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Room'),
              onTap: () {
                Navigator.pop(context);
                _showCreateRoomDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Join Room'),
              onTap: () {
                Navigator.pop(context);
                _showJoinRoomDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinRoomDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Room'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Room Code',
            hintText: 'Enter 6-character code',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code must be 6 characters')),
                );
                return;
              }
              final repo = ref.read(roomsRepositoryProvider);
              final room = await repo.getRoomByCode(code);
              if (context.mounted) {
                Navigator.pop(context);
                if (room != null) {
                  await repo.joinRoom(room.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: room.id)),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room not found')),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
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
                    MaterialPageRoute(builder: (_) => RoomLobbyScreen(roomId: room.id)),
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
