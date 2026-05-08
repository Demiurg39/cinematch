import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';

part 'swipe_provider.g.dart';

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    final cached = await repository.getCachedMovies(limit: 20);
    if (cached.isNotEmpty) return cached;

    return repository.getPopularMovies();
  }

  void onSwipe(SwipeAction action, MovieModel movie) {
    final currentDeck = state.valueOrNull ?? [];
    final updatedDeck = currentDeck.where((m) => m.id != movie.id).toList();
    state = AsyncData(updatedDeck);
  }

  Future<void> loadMore() async {
    final repository = ref.read(moviesRepositoryProvider);
    final currentDeck = state.valueOrNull ?? [];
    final newMovies = await repository.getPopularMovies(page: 2);
    state = AsyncData([...currentDeck, ...newMovies]);
  }
}
