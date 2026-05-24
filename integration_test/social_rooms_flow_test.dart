import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cinematch/features/friends/presentation/providers/friends_provider.dart';
import 'package:cinematch/features/friends/domain/friendship_model.dart';
import 'package:cinematch/features/rooms/presentation/providers/rooms_provider.dart';
import 'package:cinematch/features/rooms/presentation/providers/room_provider.dart';
import 'package:cinematch/features/rooms/domain/room_model.dart';
import 'package:cinematch/features/rooms/presentation/rooms_screen.dart';
import 'package:cinematch/features/friends/presentation/social_hub_screen.dart';

// ─── Mock Data ────────────────────────────────────────────────────────

final _mockPendingRequest = FriendshipModel(
  id: 'req-1',
  friendId: 'user-3',
  friendUsername: 'newuser',
  status: FriendshipStatus.pending,
  isIncoming: true,
  createdAt: DateTime(2025, 6, 1),
);

final _mockPendingOutgoing = FriendshipModel(
  id: 'req-2',
  friendId: 'user-3',
  friendUsername: 'newuser',
  status: FriendshipStatus.pending,
  isIncoming: false,
  createdAt: DateTime(2025, 6, 1),
);

RoomModel _createRoom({
  String id = 'room-1',
  String code = 'ABC123',
  String name = 'Test Room',
  String createdBy = 'user-1',
  RoomStatus status = RoomStatus.lobby,
  int threshold = 2,
  bool isPrivate = false,
  DateTime? timerEndAt,
}) {
  return RoomModel(
    id: id,
    code: code,
    name: name,
    createdBy: createdBy,
    status: status,
    matchThreshold: threshold,
    isPrivate: isPrivate,
    createdAt: DateTime(2025, 6, 1),
    participantIds: ['user-1', 'user-2'],
    timerEndAt: timerEndAt,
  );
}

// ─── Mock Notifiers ───────────────────────────────────────────────────

class _MockFriendsNotifier extends FriendsNotifier {
  final Stream<List<FriendshipModel>> Function() _onBuild;
  _MockFriendsNotifier(this._onBuild);

  @override
  Stream<List<FriendshipModel>> build() => _onBuild();
}

class _MockMyRoomsNotifier extends MyRoomsNotifier {
  final List<RoomModel> Function() _onBuild;
  _MockMyRoomsNotifier(this._onBuild);

  @override
  Future<List<RoomModel>> build() async => _onBuild();
}

class _MockPublicRoomsNotifier extends PublicRoomsNotifier {
  final Stream<List<RoomModel>> Function() _onBuild;
  _MockPublicRoomsNotifier(this._onBuild);

  @override
  Stream<List<RoomModel>> build() => _onBuild();
}

class _MockActiveRoomNotifier extends ActiveRoomNotifier {
  final Stream<RoomModel?> Function() _onBuild;
  _MockActiveRoomNotifier(this._onBuild);

  @override
  Stream<RoomModel?> build(String roomId) => _onBuild();
}

// ─── Helpers ──────────────────────────────────────────────────────────

Stream<List<RoomModel>> _emptyRoomStream() async* { yield []; }

// ─── Tests ────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Social & Rooms E2E Flow', () {
    // Test 1: Pending State Persistence
    testWidgets('1 - Pending state persists and is visible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendsNotifierProvider.overrideWith(
              () => _MockFriendsNotifier(
                () => Stream.value([_mockPendingOutgoing]),
              ),
            ),
          ],
          child: const MaterialApp(home: SocialHubScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('newuser'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
    });

    // Test 2: Real-Time Friend Sync
    testWidgets('2 - Real-time sync reflects accepted friend', (tester) async {
      final controller = StreamController<List<FriendshipModel>>();
      controller.add([_mockPendingRequest]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendsNotifierProvider.overrideWith(
              () => _MockFriendsNotifier(() => controller.stream),
            ),
          ],
          child: const MaterialApp(home: SocialHubScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('newuser'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      final accepted = FriendshipModel(
        id: 'req-1',
        friendId: 'user-3',
        friendUsername: 'newuser',
        status: FriendshipStatus.accepted,
        isIncoming: false,
        createdAt: DateTime(2025, 6, 1),
      );
      controller.add([accepted]);
      await tester.pumpAndSettle();

      expect(find.text('Accept'), findsNothing);
      await controller.close();
    });

    // Test 3: Adaptive Tab Transition
    testWidgets('3 - Adaptive tab shows lobby discovery or active session',
        (tester) async {
      // State A: No active rooms → lobby discovery
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRoomsNotifierProvider.overrideWith(
              () => _MockMyRoomsNotifier(() => []),
            ),
            publicRoomsNotifierProvider.overrideWith(
              () => _MockPublicRoomsNotifier(() => _emptyRoomStream()),
            ),
          ],
          child: const MaterialApp(home: RoomsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('Join Room'), findsOneWidget);
      expect(find.text('Discover Public Rooms'), findsOneWidget);

      // State B: Active room exists → session dashboard
      final activeRoom = _createRoom(
        status: RoomStatus.lobby,
        timerEndAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRoomsNotifierProvider.overrideWith(
              () => _MockMyRoomsNotifier(() => [activeRoom]),
            ),
            publicRoomsNotifierProvider.overrideWith(
              () => _MockPublicRoomsNotifier(() => _emptyRoomStream()),
            ),
            activeRoomNotifierProvider('room-1').overrideWith(
              () => _MockActiveRoomNotifier(
                () => Stream.value(activeRoom),
              ),
            ),
          ],
          child: const MaterialApp(home: RoomsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Start Voting'), findsOneWidget);
    });

    // Test 4: Timer Expiration → Shared Pool Review
    testWidgets('4 - Timer expiry triggers shared pool navigation',
        (tester) async {
      final expiredRoom = _createRoom(
        status: RoomStatus.voting,
        timerEndAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRoomsNotifierProvider.overrideWith(
              () => _MockMyRoomsNotifier(() => [expiredRoom]),
            ),
            publicRoomsNotifierProvider.overrideWith(
              () => _MockPublicRoomsNotifier(() => _emptyRoomStream()),
            ),
            activeRoomNotifierProvider('room-1').overrideWith(
              () => _MockActiveRoomNotifier(
                () => Stream.value(expiredRoom),
              ),
            ),
          ],
          child: const MaterialApp(home: RoomsScreen()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('ABC123'), findsOneWidget);
    });
  });
}