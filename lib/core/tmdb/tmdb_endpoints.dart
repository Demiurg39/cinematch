class TmdbEndpoints {
  TmdbEndpoints._();

  static const String popularMovies = '/movie/popular';
  static const String searchMovies = '/search/movie';
  static const String movieDetails = '/movie';
  static const String watchProviders = '/movie/{movie_id}/watch/providers';
  static const String genreList = '/genre/movie/list';

  static String movieDetail(int movieId) => '/movie/$movieId';
  static String movieWatchProviders(int movieId) => '/movie/$movieId/watch/providers';
}