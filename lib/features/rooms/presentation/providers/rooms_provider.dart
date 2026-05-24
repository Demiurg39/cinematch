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

@riverpod
class PublicRoomsNotifier extends _$PublicRoomsNotifier {
  @override
  Stream<List<RoomModel>> build() {
    return ref.read(roomsRepositoryProvider).watchPublicRooms();
  }
}
