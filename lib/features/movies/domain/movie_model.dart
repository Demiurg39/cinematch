class MovieModel {
  final String id;
  final int tmdbId;
  final String title;
  final String? overview;
  final int? year;
  final String? posterUrl;
  final List<String> genres;
  final double popularity;
  final int? runtime;
  final double? voteAverage;
  final int? voteCount;
  final DateTime cachedAt;
  final DateTime? lastSyncedAt;

  const MovieModel({
    required this.id,
    required this.tmdbId,
    required this.title,
    this.overview,
    this.year,
    this.posterUrl,
    this.genres = const [],
    this.popularity = 0,
    this.runtime,
    this.voteAverage,
    this.voteCount,
    required this.cachedAt,
    this.lastSyncedAt,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] as String,
      tmdbId: json['tmdb_id'] as int,
      title: json['title'] as String,
      overview: json['overview'] as String?,
      year: json['year'] as int?,
      posterUrl: json['poster_url'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      cachedAt: DateTime.parse(json['cached_at'] as String),
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'title': title,
      'overview': overview,
      'year': year,
      'poster_url': posterUrl,
      'genres': genres,
      'popularity': popularity,
      'runtime': runtime,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'cached_at': cachedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  factory MovieModel.fromTmdb(Map<String, dynamic> json, {Map<int, String>? genreMap}) {
    final releaseDate = json['release_date'] as String?;
    final genreIds = (json['genre_ids'] as List<dynamic>?)?.cast<int>() ?? [];
    final genreNames = genreMap != null
        ? genreIds.map((id) => genreMap[id]).whereType<String>().toList()
        : <String>[];
    return MovieModel(
      id: '', // Will be set by Supabase
      tmdbId: json['id'] as int,
      title: json['title'] as String? ?? 'Unknown',
      overview: json['overview'] as String?,
      year: releaseDate != null && releaseDate.isNotEmpty
          ? int.tryParse(releaseDate.split('-').first)
          : null,
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      genres: genreNames,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      cachedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );
  }

  MovieModel copyWith({
    String? id,
    int? tmdbId,
    String? title,
    String? overview,
    int? year,
    String? posterUrl,
    List<String>? genres,
    double? popularity,
    int? runtime,
    double? voteAverage,
    int? voteCount,
    DateTime? cachedAt,
    DateTime? lastSyncedAt,
  }) {
    return MovieModel(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      year: year ?? this.year,
      posterUrl: posterUrl ?? this.posterUrl,
      genres: genres ?? this.genres,
      popularity: popularity ?? this.popularity,
      runtime: runtime ?? this.runtime,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      cachedAt: cachedAt ?? this.cachedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}