import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../movies/domain/movie_model.dart';
import '../../../movies/presentation/providers/movies_provider.dart';
import '../../domain/swipe_action.dart';
import 'match_provider.dart';

part 'swipe_provider.g.dart';

@riverpod
class SwipeDeckNotifier extends _$SwipeDeckNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    final cached = await repository.getCachedMovies(limit: 20);
    if (cached.isNotEmpty) {
      cached.shuffle();
      return cached;
    }

    final movies = await repository.getPopularMovies();
    movies.shuffle();
    return movies;
  }

  Future<void> onSwipe(SwipeAction action, MovieModel movie) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await ref.read(swipeRepositoryProvider).recordSwipe(
            userId: userId,
            movie: movie,
            action: action,
          );
    }

    final currentDeck = state.valueOrNull ?? [];
    final updatedDeck = currentDeck.where((m) => m.id != movie.id).toList();

    // Load more if running low
    if (updatedDeck.length < 5) {
      final repository = ref.read(moviesRepositoryProvider);
      final newMovies = await repository.getPopularMovies(page: (currentDeck.length ~/ 20) + 1);
      newMovies.shuffle();
      state = AsyncData([...updatedDeck, ...newMovies]);
    } else {
      state = AsyncData(updatedDeck);
    }
  }

  Future<void> loadMore() async {
    final repository = ref.read(moviesRepositoryProvider);
    final currentDeck = state.valueOrNull ?? [];
    final page = (currentDeck.length ~/ 20) + 1;
    final newMovies = await repository.getPopularMovies(page: page);
    newMovies.shuffle();
    state = AsyncData([...currentDeck, ...newMovies]);
  }
}
