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
      'cached_at': cachedAt.toIso8601String(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  factory MovieModel.fromTmdb(Map<String, dynamic> json) {
    final releaseDate = json['release_date'] as String?;
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
      genres: [], // Populated separately via genre IDs or details
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
      runtime: json['runtime'] as int?,
      cachedAt: DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );
  }
}