import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/match_model.dart';

class MatchesRepository {
  final SupabaseClient _client;
  MatchesRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<MatchModel>> getMatches() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final response = await _client.from('matches').select().eq('user_id', userId);
    return response.map((json) => MatchModel.fromJson(json)).toList();
  }

  Stream<List<MatchModel>> watchMatches() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    return _client.from('matches').stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data.map((json) => MatchModel.fromJson(json)).toList());
  }
}
