import 'package:supabase_flutter/supabase_flutter.dart';
import '../../movies/domain/movie_model.dart';

class PartnerAnalyticsRepository {
  final SupabaseClient _client;
  PartnerAnalyticsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<MovieModel>> getTogetherHistory(String partnerLinkId) async {
    final response = await _client
        .from('partner_watch_history')
        .select('movie_id, watched_at, movies!partner_watch_history_movie_id_fkey(*)')
        .eq('partner_link_id', partnerLinkId)
        .order('watched_at', ascending: false);

    return response.map((json) {
      final movieJson = json['movies'] as Map<String, dynamic>;
      return MovieModel.fromJson(movieJson);
    }).toList();
  }

  Future<Map<String, double>> getGenreHarmony(String partnerLinkId) async {
    final movies = await getTogetherHistory(partnerLinkId);

    final genreCounts = <String, int>{};
    int total = 0;
    for (final movie in movies) {
      for (final genre in movie.genres) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
        total++;
      }
    }

    if (total == 0) return {};

    return genreCounts.map((genre, count) => MapEntry(genre, count / total));
  }

  Future<Duration> getTimeSpent(String partnerLinkId) async {
    final response = await _client
        .from('partner_watch_history')
        .select('movie_id, movies!partner_watch_history_movie_id_fkey(runtime)')
        .eq('partner_link_id', partnerLinkId);

    int totalMinutes = 0;
    for (final json in response) {
      final movieJson = json['movies'] as Map<String, dynamic>?;
      final runtime = movieJson?['runtime'] as int?;
      if (runtime != null) totalMinutes += runtime;
    }

    return Duration(minutes: totalMinutes);
  }

  Future<int> getTogetherCount(String partnerLinkId) async {
    final response = await _client
        .from('partner_watch_history')
        .select('id')
        .eq('partner_link_id', partnerLinkId);

    return (response as List).length;
  }

  Future<void> addToTogetherHistory({
    required String partnerLinkId,
    required String movieId,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('partner_watch_history').insert({
      'partner_link_id': partnerLinkId,
      'movie_id': movieId,
      'added_by': uid,
      'watched_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFromTogetherHistory(String watchHistoryId) async {
    await _client.from('partner_watch_history').delete().eq('id', watchHistoryId);
  }
}