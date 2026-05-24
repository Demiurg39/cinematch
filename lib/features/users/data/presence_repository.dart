import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceRepository {
  final SupabaseClient _client;
  PresenceRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> setOnline() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('user_presence').upsert({
      'user_id': uid,
      'is_online': true,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setOffline() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('user_presence').upsert({
      'user_id': uid,
      'is_online': false,
      'last_seen_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<bool> watchUserPresence(String userId) {
    return _client.from('user_presence').stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
      if (data.isEmpty) return false;
      return data.first['is_online'] as bool? ?? false;
    });
  }
}
