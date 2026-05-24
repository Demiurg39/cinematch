import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/room_provider.dart';
import 'providers/rooms_provider.dart';
import '../domain/room_model.dart';
import '../../swipe/presentation/swipe_screen.dart';
import '../../swipe/presentation/providers/swipe_provider.dart';
import '../../users/presentation/providers/presence_provider.dart';
import '../../../core/presentation/widgets/confirm_dialog.dart';
import 'widgets/invite_friends_sheet.dart';
import 'widgets/timer_picker.dart';
import 'shared_pool_review_screen.dart';

class RoomsScreen extends ConsumerStatefulWidget {
  const RoomsScreen({super.key});

  @override
  ConsumerState<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsScreen> {
  bool _showLobbyDiscovery = false;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(myRoomsNotifierProvider);

    return roomsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (rooms) {
        final activeRooms = rooms.where((r) =>
          r.status == RoomStatus.lobby ||
          r.status == RoomStatus.voting ||
          r.status == RoomStatus.matched ||
          r.status == RoomStatus.revealed
        ).toList();

        final showActiveSession = activeRooms.isNotEmpty && !_showLobbyDiscovery;

        if (showActiveSession) {
          final activeRoom = _pickActiveRoom(activeRooms);
          return _ActiveRoomDashboard(
            room: activeRoom,
            onBackToLobby: () {
              setState(() => _showLobbyDiscovery = true);
            },
          );
        }

        return _LobbyDiscoveryView(
          rooms: rooms,
          onEnterActiveRoom: () {
            setState(() => _showLobbyDiscovery = false);
          },
        );
      },
    );
  }

  RoomModel _pickActiveRoom(List<RoomModel> rooms) {
    if (rooms.length == 1) return rooms.first;
    // Priority: voting > matched > revealed > lobby
    final priority = {
      RoomStatus.voting: 0,
      RoomStatus.matched: 1,
      RoomStatus.revealed: 2,
      RoomStatus.lobby: 3,
    };
    rooms.sort((a, b) => (priority[a.status] ?? 99).compareTo(priority[b.status] ?? 99));
    return rooms.first;
  }
}

// ============================================================================
// State A — Lobby Discovery
// ============================================================================

class _LobbyDiscoveryView extends ConsumerWidget {
  final List<RoomModel> rooms;
  final VoidCallback onEnterActiveRoom;

  const _LobbyDiscoveryView({
    required this.rooms,
    required this.onEnterActiveRoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final publicRoomsStream = ref.watch(publicRoomsNotifierProvider);
    final activeRooms = rooms.where((r) =>
      r.status != RoomStatus.archived && r.status != RoomStatus.completed
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          if (activeRooms.isNotEmpty)
            TextButton.icon(
              onPressed: onEnterActiveRoom,
              icon: const Icon(Icons.meeting_room, size: 18),
              label: const Text('Active Room'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active room banner
          if (activeRooms.isNotEmpty) ...[
            _ActiveRoomBanner(room: activeRooms.first, onTap: onEnterActiveRoom),
            const SizedBox(height: 16),
          ],

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add,
                  label: 'Create Room',
                  onTap: () => _showCreateRoomDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.login,
                  label: 'Join Room',
                  onTap: () => _showJoinRoomDialog(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Discovery section
          Text('Discover Public Rooms', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          publicRoomsStream.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Could not load rooms')),
            data: (discoverRooms) {
              if (discoverRooms.isEmpty) {
                return _EmptyDiscovery(theme: theme);
              }
              return SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: discoverRooms.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final room = discoverRooms[index];
                    return _PublicRoomCard(room: room);
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Text('Your Rooms', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('No rooms yet', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            )
          else
            ...rooms.reversed.map((room) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RoomHistoryCard(room: room),
            )),
        ],
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length != 6) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code must be 6 characters')),
                  );
                }
                return;
              }
              final repo = ref.read(roomsRepositoryProvider);
              final room = await repo.getRoomByCode(code);
              if (context.mounted) {
                Navigator.pop(context);
                if (room != null) {
                  await repo.joinRoom(room.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Joined ${room.name}')),
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
    final nameController = TextEditingController();
    bool isPrivate = false;
    int matchThreshold = 2;
    Duration timerDuration = const Duration(minutes: 5);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Room Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Private Room'),
                  subtitle: Text(isPrivate
                      ? 'Only invited users can join'
                      : 'Anyone with the code can join'),
                  value: isPrivate,
                  onChanged: (v) => setDialogState(() => isPrivate = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Text('Match Threshold', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Half'), selected: matchThreshold == 2,
                      onSelected: (_) => setDialogState(() => matchThreshold = 2)),
                    ChoiceChip(label: const Text('Majority'), selected: matchThreshold == 3,
                      onSelected: (_) => setDialogState(() => matchThreshold = 3)),
                    ChoiceChip(label: const Text('Unanimous'), selected: matchThreshold == 4,
                      onSelected: (_) => setDialogState(() => matchThreshold = 4)),
                  ],
                ),
                const SizedBox(height: 16),
                TimerPicker(
                  selectedDuration: timerDuration,
                  onChanged: (d) => setDialogState(() => timerDuration = d),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final repo = ref.read(roomsRepositoryProvider);
                final room = await repo.createRoom(
                  name: nameController.text,
                  matchThreshold: matchThreshold,
                  isPrivate: isPrivate,
                );
                // Set timer on the room
                await repo.setRoomTimer(room.id, timerDuration);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created ${room.name} — Code: ${room.code}')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// State B — Active Room Dashboard
// ============================================================================

class _ActiveRoomDashboard extends ConsumerStatefulWidget {
  final RoomModel room;
  final VoidCallback onBackToLobby;

  const _ActiveRoomDashboard({
    required this.room,
    required this.onBackToLobby,
  });

  @override
  ConsumerState<_ActiveRoomDashboard> createState() => _ActiveRoomDashboardState();
}

class _ActiveRoomDashboardState extends ConsumerState<_ActiveRoomDashboard> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;
  bool _navigatedToPool = false;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer() {
    final room = widget.room;
    if (room.timerEndAt != null) {
      final remaining = room.timerEndAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        _timeRemaining = Duration.zero;
        _onTimerExpired();
      } else {
        _startCountdown(room.timerEndAt!);
      }
    }
  }

  @override
  void didUpdateWidget(_ActiveRoomDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.timerEndAt != widget.room.timerEndAt) {
      _initTimer();
    }
  }

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
    if (_navigatedToPool) return;
    final room = widget.room;
    if (room.status == RoomStatus.voting) {
      _navigatedToPool = true;
      // Auto-navigate to shared pool review
      Future.microtask(() {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedPoolReviewScreen(roomId: room.id),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch room for real-time updates
    final roomAsync = ref.watch(activeRoomNotifierProvider(widget.room.id));
    final theme = Theme.of(context);
    final isCreator = widget.room.createdBy == ref.read(roomsRepositoryProvider).currentUserId;

    return roomAsync.when(
      loading: () => Scaffold(body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        if (room == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onBackToLobby());
          return const Scaffold(body: Center(child: Text('Room deleted')));
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
                  builder: (_) => InviteFriendsSheet(roomId: room.id),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Rooms',
                onPressed: widget.onBackToLobby,
              ),
            ],
          ),
          body: Column(
            children: [
              // Room info header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Code: ${room.code}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(label: Text(room.status.name.toUpperCase())),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: Icon(room.isPrivate ? Icons.lock : Icons.lock_open, size: 14),
                          label: Text(room.isPrivate ? 'Private' : 'Public'),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.groups, size: 14),
                          label: Text('${room.matchThreshold}/4'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    // Swiping activity indicator
                    if (room.status == RoomStatus.voting)
                      _SwipingActivityIndicator(roomId: room.id),
                  ],
                ),
              ),

              // Countdown timer
              if (room.timerEndAt != null && _timeRemaining.inSeconds > 0)
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
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Live settings (admin only)
              if (isCreator && room.status == RoomStatus.lobby)
                _LiveSettingsPanel(
                  room: room,
                  onChanged: () => ref.invalidate(myRoomsNotifierProvider),
                ),

              // Participants
              Expanded(
                child: _ParticipantsList(
                  roomId: room.id,
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
                    if (room.status == RoomStatus.lobby && !isCreator)
                      Text('Waiting for host to start...', style: theme.textTheme.bodySmall),
                    if (room.status == RoomStatus.voting)
                      _buildSwipingButton(room),
                    if (room.status == RoomStatus.matched || room.status == RoomStatus.revealed)
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharedPoolReviewScreen(roomId: room.id),
                          ),
                        ),
                        child: const Text('Review Shared Matches'),
                      ),
                    if (room.status != RoomStatus.voting)
                      TextButton(
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context: context,
                            title: 'Leave Room',
                            message: 'Leave ${room.name}?',
                            confirmLabel: 'Leave',
                          );
                          if (confirmed == true && mounted) {
                            await ref.read(activeRoomNotifierProvider(room.id).notifier).leave();
                            widget.onBackToLobby();
                          }
                        },
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
          onPressed: () async {
            final repo = ref.read(roomsRepositoryProvider);
            final notifier = ref.read(activeRoomNotifierProvider(room.id).notifier);

            // Ownership fallback: check if admin is online
            final userId = ref.read(roomsRepositoryProvider).currentUserId;
            if (userId != null && room.createdBy != userId) {
              // Current user isn't admin — check fallback eligibility
              final presenceClient = Supabase.instance.client;
              final adminPresence = await presenceClient.from('user_presence')
                  .select('is_online')
                  .eq('user_id', room.createdBy)
                  .maybeSingle();
              final adminOnline = adminPresence?['is_online'] as bool? ?? false;

              if (!adminOnline) {
                // Admin offline — transfer to this user
                await repo.transferOwnership(room.id, userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin offline — ownership transferred to you')),
                  );
                }
              }
            }

            if (room.timerEndAt == null) {
              await notifier.setTimer(const Duration(minutes: 5));
            } else {
              await notifier.startVoting();
            }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: () {
            ref.read(swipeDeckNotifierProvider.notifier).setRoomId(room.id);
            ref.read(popularDeckNotifierProvider.notifier).setRoomId(room.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SwipeScreen(roomId: room.id),
              ),
            );
          },
          icon: const Icon(Icons.swipe),
          label: const Text('Start Swiping'),
        ),
        const SizedBox(height: 4),
        Text('Swipe to find shared matches', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ============================================================================
// Live Settings Panel (admin only)
// ============================================================================

class _LiveSettingsPanel extends ConsumerWidget {
  final RoomModel room;
  final VoidCallback onChanged;

  const _LiveSettingsPanel({
    required this.room,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Room Settings', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Private'),
                  const Spacer(),
                  Switch(
                    value: room.isPrivate,
                    onChanged: (v) {
                      ref.read(roomsRepositoryProvider).updateRoomSettings(
                        room.id,
                        isPrivate: v,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Timer', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              TimerPicker(
                selectedDuration: room.timerEndAt != null
                    ? room.timerEndAt!.difference(DateTime.now())
                    : const Duration(minutes: 5),
                onChanged: (d) {
                  ref.read(roomsRepositoryProvider).updateTimerDuration(room.id, d);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Swiping Activity Indicator
// ============================================================================

class _SwipingActivityIndicator extends ConsumerStatefulWidget {
  final String roomId;
  const _SwipingActivityIndicator({required this.roomId});

  @override
  ConsumerState<_SwipingActivityIndicator> createState() => _SwipingActivityIndicatorState();
}

class _SwipingActivityIndicatorState extends ConsumerState<_SwipingActivityIndicator> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: StreamBuilder(
        stream: () {
          final client = Supabase.instance.client;
          return client.from('swipes').stream(primaryKey: ['id'])
              .eq('room_id', widget.roomId);
        }(),
        builder: (context, snapshot) {
          final count = (snapshot.data as List?)?.length ?? 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count swipes cast',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// Shared widgets
// ============================================================================

class _ActiveRoomBanner extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const _ActiveRoomBanner({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.meeting_room),
        title: Text('Active: ${room.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${room.status.name.toUpperCase()} · Code: ${room.code}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicRoomCard extends ConsumerWidget {
  final RoomModel room;

  const _PublicRoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final repo = ref.read(roomsRepositoryProvider);
            await repo.joinRoom(room.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined ${room.name}')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (room.isPrivate)
                      const Icon(Icons.lock, size: 14),
                  ],
                ),
                const Spacer(),
                Text('Code: ${room.code}', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(label: Text(room.status.name, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                    const Spacer(),
                    Text('+Join', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomHistoryCard extends StatelessWidget {
  final RoomModel room;

  const _RoomHistoryCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = room.status != RoomStatus.archived && room.status != RoomStatus.completed;

    return Card(
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(room.name, overflow: TextOverflow.ellipsis)),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
              ),
            ],
            if (room.isPrivate) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock, size: 14, color: theme.colorScheme.outline),
            ],
          ],
        ),
        subtitle: Text('Code: ${room.code} · ${room.status.name}'),
        trailing: Chip(label: Text(room.status.name)),
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  final ThemeData theme;

  const _EmptyDiscovery({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('No public rooms', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Create one to get started', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================================
// Participants List
// ============================================================================

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
            ...participants.map((userId) {
              final isHost = userId == createdBy;
              // Watch presence for this participant
              final isOnline = ref.watch(userPresenceProvider(userId));

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(userId[0].toUpperCase()),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline.valueOrNull == true ? Colors.green : Colors.grey,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(isHost
                    ? 'Creator'
                    : userId.length > 8
                        ? '${userId.substring(0, 8)}...'
                        : userId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHost)
                      const Chip(label: Text('Host'))
                    else if (isCreator)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'transfer') {
                            ref.read(roomsRepositoryProvider).transferOwnership(roomId, userId);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'transfer', child: Text('Transfer Ownership')),
                        ],
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}