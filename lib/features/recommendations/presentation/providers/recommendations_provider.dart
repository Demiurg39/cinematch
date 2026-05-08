import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/recommendations_repository.dart';
import '../../../movies/domain/movie_model.dart';

part 'recommendations_provider.g.dart';

@riverpod
RecommendationsRepository recommendationsRepository(RecommendationsRepositoryRef ref) {
  return RecommendationsRepository();
}

@riverpod
class RecommendationsNotifier extends _$RecommendationsNotifier {
  @override
  Future<List<MovieModel>> build() async {
    return ref.read(recommendationsRepositoryProvider).getRecommendations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(recommendationsRepositoryProvider).getRecommendations());
  }

  Future<void> updateClusters() async {
    await ref.read(recommendationsRepositoryProvider).updateUserClusters();
    await refresh();
  }
}
