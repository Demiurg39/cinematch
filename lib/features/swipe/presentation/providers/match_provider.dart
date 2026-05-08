import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../swipe/data/swipe_repository.dart';

part 'match_provider.g.dart';

@riverpod
SwipeRepository swipeRepository(SwipeRepositoryRef ref) {
  return SwipeRepository();
}

@riverpod
class MatchNotifier extends _$MatchNotifier {
  @override
  Stream<List<Map<String, dynamic>>> build() {
    final repo = ref.read(swipeRepositoryProvider);
    final userId = repo.currentUserId;
    if (userId == null) return Stream.value([]);
    return repo.watchMatches(userId);
  }
}
