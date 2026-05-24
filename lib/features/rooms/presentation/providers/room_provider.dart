import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/room_model.dart';
import '../../domain/room_match_model.dart';
import 'rooms_provider.dart';

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

  Future<void> setTimer(Duration duration) async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).setRoomTimer(room.id, duration);
    }
  }

  Future<void> markMatched() async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).updateRoomStatus(room.id, RoomStatus.matched);
    }
  }

  Future<void> revealMatches() async {
    final room = state.valueOrNull;
    if (room != null) {
      await ref.read(roomsRepositoryProvider).updateRoomStatus(room.id, RoomStatus.revealed);
    }
  }
}

@riverpod
class RoomMatchNotifier extends _$RoomMatchNotifier {
  @override
  RoomMatch? build(String roomId) {
    return null;
  }

  void setMatch(RoomMatch match) {
    state = match;
  }

  void clear() {
    state = null;
  }
}