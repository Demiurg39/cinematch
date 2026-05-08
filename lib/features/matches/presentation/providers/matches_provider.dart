import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/matches_repository.dart';
import '../../domain/match_model.dart';

part 'matches_provider.g.dart';

@riverpod
MatchesRepository matchesRepository(MatchesRepositoryRef ref) {
  return MatchesRepository();
}

@riverpod
class MatchesNotifier extends _$MatchesNotifier {
  @override
  Stream<List<MatchModel>> build() {
    return ref.read(matchesRepositoryProvider).watchMatches();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
