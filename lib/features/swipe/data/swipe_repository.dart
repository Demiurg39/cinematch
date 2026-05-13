import 'package:supabase_flutter/supabase_flutter.dart';
import '../../movies/domain/movie_model.dart';
import '../domain/swipe_action.dart';

class SwipeRepository {
  final SupabaseClient _client;
  SwipeRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> recordSwipe({
    required String userId,
    required MovieModel movie,
    required SwipeAction action,
  }) async {
    // If movie.id is empty (from TMDB), lookup by tmdbId first
    String? movieDbId = movie.id.isEmpty ? null : movie.id;
    if (movieDbId == null) {
      final cached = await _client.from('movies').select('id').eq('tmdb_id', movie.tmdbId).maybeSingle();
      movieDbId = cached?['id'] as String?;
    }

    // If movie still not in DB, insert it first
    if (movieDbId == null) {
      final now = DateTime.now().toIso8601String();
      final inserted = await _client.from('movies').upsert({
        'tmdb_id': movie.tmdbId,
        'title': movie.title,
        'overview': movie.overview,
        'year': movie.year,
        'poster_url': movie.posterUrl,
        'genres': movie.genres,
        'popularity': movie.popularity,
        'runtime': movie.runtime,
        'cached_at': now,
        'last_synced_at': now,
      }, onConflict: 'tmdb_id').select('id').maybeSingle();
      movieDbId = inserted?['id'] as String?;
    }

    if (movieDbId == null) return; // Still can't record

    await _client.from('swipes').insert({
      'user_id': userId,
      'movie_id': movieDbId,
      'direction': action.name,
    });
  }

  Future<List<Map<String, dynamic>>> getSwipeActionsForMovie(int tmdbId) async {
    // First find movie uuid by tmdb_id
    final movie = await _client.from('movies').select('id').eq('tmdb_id', tmdbId).maybeSingle();
    if (movie == null) return [];

    final result = await _client.from('swipes').select(
      'user_id',
    ).eq('movie_id', movie['id']).eq('direction', 'like');
    return result;
  }

  Future<List<Map<String, dynamic>>> getMatches() async {
    final result = await _client.from('matches').select('*').order('created_at', ascending: false);
    return result;
  }

  Stream<List<Map<String, dynamic>>> watchMatches(String userId) {
    return _client.from('matches').stream(primaryKey: ['id']).eq('user_id', userId);
  }
}
