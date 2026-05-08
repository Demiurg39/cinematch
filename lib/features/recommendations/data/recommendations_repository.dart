import 'package:supabase_flutter/supabase_flutter.dart';
import '../../movies/domain/movie_model.dart';

class RecommendationsRepository {
  final SupabaseClient _client;
  RecommendationsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<MovieModel>> getRecommendations({int limit = 20}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client.rpc('get_recommendations', params: {
      'user_uuid': userId,
      'limit_count': limit,
    });

    if (response == null) return [];

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => MovieModel.fromTmdb(json as Map<String, dynamic>)).toList();
  }

  Future<void> updateUserClusters() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.rpc('update_user_clusters', params: {
      'user_uuid': userId,
    });
  }

  Future<List<List<int>>> getUserClusterAssignments() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client.rpc('get_user_cluster_assignments', params: {
      'user_uuid': userId,
    });

    if (response == null) return [];

    final List<dynamic> data = response as List<dynamic>;
    return data.map((row) {
      final r = row as Map<String, dynamic>;
      return [(r['cluster_0'] as int?) ?? 0, (r['cluster_1'] as int?) ?? 0, (r['cluster_2'] as int?) ?? 0];
    }).toList();
  }
}
