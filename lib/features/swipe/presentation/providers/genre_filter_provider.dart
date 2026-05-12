import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../movies/presentation/providers/movies_provider.dart';

part 'genre_filter_provider.g.dart';

@riverpod
class GenreFilterNotifier extends _$GenreFilterNotifier {
  @override
  Map<String, dynamic> build() {
    return {
      'selectedGenres': <int>[],
      'availableGenres': <Map<String, dynamic>>[],
    };
  }

  Future<void> loadGenres() async {
    final repo = ref.read(moviesRepositoryProvider);
    final genres = await repo.getGenreList();
    state = {...state, 'availableGenres': genres};
  }

  void toggleGenre(int genreId) {
    final current = List<int>.from(state['selectedGenres'] as List<int>);
    if (current.contains(genreId)) {
      current.remove(genreId);
    } else {
      current.add(genreId);
    }
    state = {...state, 'selectedGenres': current};
  }

  void clearGenres() {
    state = {...state, 'selectedGenres': []};
  }
}
