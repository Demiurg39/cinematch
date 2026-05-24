import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../features/swipe/presentation/providers/match_provider.dart';

part 'shared_matches_provider.g.dart';

@riverpod
class SharedMatchesNotifier extends _$SharedMatchesNotifier {
  @override
  Future<Set<String>> build(String roomId) async {
    final repo = ref.read(swipeRepositoryProvider);
    return repo.getSharedMutualMatches(roomId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(swipeRepositoryProvider);
      return repo.getSharedMutualMatches(state.requireValue.first);
    });
  }
}
