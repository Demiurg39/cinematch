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
    await _client.from('swipes').insert({
      'user_id': userId,
      'tmdb_id': movie.tmdbId,
      'action': action.name,
    });
  }

  Future<List<Map<String, dynamic>>> getSwipeActionsForMovie(int tmdbId) async {
    final result = await _client.from('swipes').select(
      'user_id',
    ).eq('tmdb_id', tmdbId).eq('action', 'like');
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
