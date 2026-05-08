class MatchModel {
  final String id;
  final String oderId;
  final int tmdbId;
  final String? movieTitle;
  final String? posterUrl;
  final DateTime createdAt;
  final String matchedUserId;
  final String matchedUsername;

  const MatchModel({
    required this.id,
    required this.oderId,
    required this.tmdbId,
    this.movieTitle,
    this.posterUrl,
    required this.createdAt,
    required this.matchedUserId,
    required this.matchedUsername,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      tmdbId: json['tmdb_id'] as int,
      movieTitle: json['movie_title'] as String?,
      posterUrl: json['poster_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      matchedUserId: json['matched_userId'] as String? ?? '',
      matchedUsername: json['matched_username'] as String? ?? 'Unknown',
    );
  }
}
