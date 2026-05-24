import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/room_provider.dart';
import 'providers/rooms_provider.dart';
import '../domain/room_model.dart';
import '../../swipe/presentation/swipe_screen.dart';
import '../../swipe/presentation/providers/swipe_provider.dart';
import 'widgets/invite_friends_sheet.dart';
import 'shared_pool_review_screen.dart';

class RoomLobbyScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomLobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends ConsumerState<RoomLobbyScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _navigatedOnExpiry = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime endAt) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = endAt.difference(DateTime.now());
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        setState(() => _timeRemaining = Duration.zero);
        _onTimerExpired();
      } else {
        setState(() => _timeRemaining = remaining);
      }
    });
  }

  void _onTimerExpired() {
    if (_navigatedOnExpiry) return;
    _navigatedOnExpiry = true;
    Future.microtask(() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SharedPoolReviewScreen(roomId: widget.roomId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(activeRoomNotifierProvider(widget.roomId));
    final theme = Theme.of(context);

    return roomAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        if (room == null) {
          return const Scaffold(body: Center(child: Text('Room not found')));
        }

        final isCreator = room.createdBy == ref.read(roomsRepositoryProvider).currentUserId;
        final now = DateTime.now();
        if (room.timerEndAt != null && room.timerEndAt!.isAfter(now) && _timeRemaining == Duration.zero) {
          _startCountdown(room.timerEndAt!);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Invite Friends',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => InviteFriendsSheet(roomId: widget.roomId),
                ),
              ),
              if (!room.isPrivate)
                Icon(Icons.lock_open, size: 18, color: theme.colorScheme.outline),
            ],
          ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(label: Text(room.status.name.toUpperCase())),
                        if (room.isPrivate)
                          Chip(
                            avatar: const Icon(Icons.lock, size: 14),
                            label: const Text('Private'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Countdown timer (visible during voting)
              if (room.status == RoomStatus.voting && _timeRemaining.inSeconds > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_timeRemaining.inMinutes}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Participants
              Expanded(
                child: _ParticipantsList(
                  roomId: widget.roomId,
                  isCreator: isCreator,
                  createdBy: room.createdBy,
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (room.status == RoomStatus.lobby && isCreator)
                      _buildStartVotingButton(room),
                    if (room.status == RoomStatus.voting)
                      _buildSwipingButton(room),
                    if (room.status == RoomStatus.matched)
                      FilledButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => SwipeScreen(roomId: widget.roomId)),
                        ),
                        child: const Text('Keep Swiping'),
                      ),
                    if (room.status == RoomStatus.revealed || room.status == RoomStatus.matched)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharedPoolReviewScreen(roomId: widget.roomId),
                          ),
                        ),
                        child: const Text('Review Shared Matches'),
                      ),
                    // Leave room button
                    if (!isCreator)
                      TextButton(
                        onPressed: () => ref.read(activeRoomNotifierProvider(widget.roomId).notifier).leave(),
                        child: const Text('Leave Room'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartVotingButton(RoomModel room) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () {
            ref.read(activeRoomNotifierProvider(widget.roomId).notifier).startVoting();
            if (room.timerEndAt != null) {
              _startCountdown(room.timerEndAt!);
            }
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Voting'),
        ),
        const SizedBox(height: 8),
        Text(
          'Threshold: ${room.matchThreshold}/4 must agree',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSwipingButton(RoomModel room) {
    return FilledButton(
      onPressed: () {
        // Set room context on swipe providers
        ref.read(swipeDeckNotifierProvider.notifier).setRoomId(widget.roomId);
        ref.read(popularDeckNotifierProvider.notifier).setRoomId(widget.roomId);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SwipeScreen(roomId: widget.roomId)),
        );
      },
      child: const Text('Start Swiping'),
    );
  }
}

class _ParticipantsList extends ConsumerWidget {
  final String roomId;
  final bool isCreator;
  final String createdBy;

  const _ParticipantsList({
    required this.roomId,
    required this.isCreator,
    required this.createdBy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<List<String>>(
      future: ref.read(roomsRepositoryProvider).getRoomParticipantIds(roomId),
      builder: (context, snapshot) {
        final participants = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Text('Participants (${participants.length})', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ...participants.map((userId) => ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(userId[0].toUpperCase()),
              ),
              title: Text(userId == createdBy ? 'Creator' : userId),
              trailing: userId == createdBy
                  ? const Chip(label: Text('Host'))
                  : (isCreator
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'transfer') {
                              ref.read(roomsRepositoryProvider).transferOwnership(roomId, userId);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'transfer',
                              child: Text('Transfer Ownership'),
                            ),
                          ],
                        )
                      : null),
            )),
          ],
        );
      },
    );
  }
}