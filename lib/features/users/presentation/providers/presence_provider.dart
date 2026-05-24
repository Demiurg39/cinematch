
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/presence_repository.dart';

part 'presence_provider.g.dart';

@riverpod
PresenceRepository presenceRepository(PresenceRepositoryRef ref) {
  return PresenceRepository();
}

@riverpod
Stream<bool> userPresence(UserPresenceRef ref, String userId) {
  final repo = ref.watch(presenceRepositoryProvider);
  return repo.watchUserPresence(userId);
}

@riverpod
class MyPresenceNotifier extends _$MyPresenceNotifier {
  final PresenceRepository? _repo = null;

  @override
  Future<void> build() async {
    final repo = ref.read(presenceRepositoryProvider);
    ref.onDispose(() {
      // Don't read ref during dispose — container may be gone
    });
    await repo.setOnline();
  }

  Future<void> setOnline() async {
    await ref.read(presenceRepositoryProvider).setOnline();
  }

  Future<void> setOffline() async {
    await ref.read(presenceRepositoryProvider).setOffline();
  }
}
