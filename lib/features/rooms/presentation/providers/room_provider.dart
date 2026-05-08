import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/room_model.dart';
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
}
