import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/room_provider.dart';
import 'providers/rooms_provider.dart';
import '../domain/room_model.dart';
import '../../swipe/presentation/swipe_screen.dart';

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
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        if (room == null) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }

        final isCreator = room.createdBy == ref.read(roomsRepositoryProvider).currentUserId;

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
                child: Center(child: Text('${room.participantIds.length} participants')),
              ),
              if (room.status == RoomStatus.lobby && isCreator)
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
