import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/movies_repository.dart';
import '../../domain/movie_model.dart';

part 'movies_provider.g.dart';

@riverpod
MoviesRepository moviesRepository(MoviesRepositoryRef ref) {
  return MoviesRepository();
}

@riverpod
class PopularMoviesNotifier extends _$PopularMoviesNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getPopularMovies();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(moviesRepositoryProvider);
      return repository.getPopularMovies();
    });
  }

  Future<void> loadMore(int page) async {
    final currentMovies = state.valueOrNull ?? [];
    final newMovies = await ref.read(moviesRepositoryProvider).getPopularMovies(page: page);
    state = AsyncData([...currentMovies, ...newMovies]);
  }
}

@riverpod
class MovieSearchNotifier extends _$MovieSearchNotifier {
  @override
  Future<List<MovieModel>> build() async {
    return [];
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(moviesRepositoryProvider);
      return repository.searchMovies(query);
    });
  }

  void clear() {
    state = const AsyncData([]);
  }
}

@riverpod
class CachedMoviesNotifier extends _$CachedMoviesNotifier {
  @override
  Future<List<MovieModel>> build() async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getCachedMovies();
  }
}

@riverpod
class WatchProvidersNotifier extends _$WatchProvidersNotifier {
  @override
  Future<Map<String, dynamic>?> build(int tmdbId) async {
    final repository = ref.read(moviesRepositoryProvider);
    return repository.getWatchProviders(tmdbId);
  }
}