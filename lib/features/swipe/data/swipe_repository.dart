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
    String? roomId,
  }) async {
    String? movieDbId = movie.id.isEmpty ? null : movie.id;
    if (movieDbId == null) {
      final cached = await _client.from('movies').select('id').eq('tmdb_id', movie.tmdbId).maybeSingle();
      movieDbId = cached?['id'] as String?;
    }

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

    if (movieDbId == null) return;

    final insert = {
      'user_id': userId,
      'movie_id': movieDbId,
      'direction': action.name,
    };
    if (roomId != null) insert['room_id'] = roomId;

    await _client.from('swipes').insert(insert);
  }

  Future<bool> checkUnanimousMatch(String roomId, String movieDbId) async {
    final participants = await _client.from('room_members').select('user_id')
        .eq('room_id', roomId);

    if (participants.isEmpty) return false;

    final likes = await _client.from('swipes').select('user_id')
        .eq('movie_id', movieDbId)
        .eq('room_id', roomId)
        .eq('direction', 'like');

    final likedUserIds = likes.map((r) => r['user_id'] as String).toSet();
    final allLiked = participants.every((p) => likedUserIds.contains(p['user_id'] as String));
    return likedUserIds.length >= 2 && allLiked;
  }

  Future<Set<int>> getPartnerLikedTmdbIds(String partnerId, String roomId) async {
    final swipes = await _client.from('swipes').select('movie_id')
        .eq('user_id', partnerId)
        .eq('room_id', roomId)
        .eq('direction', 'like');

    if (swipes.isEmpty) return {};

    final movieIds = swipes.map((r) => r['movie_id'] as String).toList();
    final movies = await _client.from('movies').select('tmdb_id')
        .inFilter('id', movieIds);

    return movies.map((r) => r['tmdb_id'] as int).toSet();
  }

  Future<Set<String>> getSharedMutualMatches(String roomId) async {
    final members = await _client.from('room_members').select('user_id')
        .eq('room_id', roomId);
    if (members.length < 2) return {};

    final memberUserIds = members.map((r) => r['user_id'] as String).toList();

    final allSwipes = await _client.from('swipes').select('user_id, movie_id')
        .eq('room_id', roomId)
        .eq('direction', 'like');

    final movieLikeCounts = <String, int>{};
    for (final swipe in allSwipes) {
      final movieId = swipe['movie_id'] as String;
      movieLikeCounts[movieId] = (movieLikeCounts[movieId] ?? 0) + 1;
    }

    final threshold = members.length >= 3 ? 2 : 2;
    return movieLikeCounts.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toSet();
  }

  Future<List<Map<String, dynamic>>> getSwipeActionsForMovie(int tmdbId) async {
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