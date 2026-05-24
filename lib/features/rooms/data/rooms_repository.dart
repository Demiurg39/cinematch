import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/room_model.dart';

class RoomsRepository {
  final SupabaseClient _client;
  RoomsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<RoomModel> createRoom({
    required String name,
    required int matchThreshold,
    bool isPrivate = false,
  }) async {
    final code = _generateRoomCode();
    final userId = currentUserId!;

    final response = await _client.from('rooms').insert({
      'code': code,
      'name': name,
      'created_by': userId,
      'status': 'lobby',
      'match_threshold': RoomModel.thresholdToDbValue(matchThreshold),
      'is_private': isPrivate,
    }).select().single();

    await _client.from('room_members').insert({
      'room_id': response['id'],
      'user_id': userId,
    });

    return RoomModel.fromJson(response);
  }

  Future<RoomModel?> getRoomByCode(String code) async {
    final response = await _client.from('rooms').select().eq('code', code).maybeSingle();
    if (response == null) return null;
    return RoomModel.fromJson(response);
  }

  Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').insert({
      'room_id': roomId,
      'user_id': currentUserId,
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('room_members').delete()
        .eq('room_id', roomId).eq('user_id', uid);
  }

  Future<List<RoomModel>> getMyRooms() async {
    final userId = currentUserId!;
    // Get rooms through room_members junction table using inner join
    final response = await _client.from('rooms').select('*, room_members!inner(user_id)')
        .eq('room_members.user_id', userId);

    if (response.isEmpty) return [];

    return response.map((json) => RoomModel.fromJson(json)).toList();
  }

  Future<List<String>> getRoomParticipantIds(String roomId) async {
    final response = await _client.from('room_members').select('user_id')
        .eq('room_id', roomId);

    return response.map((r) => r['user_id'] as String).toList();
  }

  Stream<List<RoomModel>> watchPublicRooms() {
    return _client.from('rooms').stream(primaryKey: ['id'])
        .eq('is_private', false)
        .map((data) => data
            .where((r) => r['status'] != 'archived' && r['status'] != 'completed')
            .map((json) => RoomModel.fromJson(json))
            .toList());
  }

  Future<void> transferOwnership(String roomId, String newOwnerId) async {
    await _client.from('rooms').update({'created_by': newOwnerId}).eq('id', roomId);
  }

  Future<void> setRoomTimer(String roomId, Duration duration) async {
    final endAt = DateTime.now().add(duration);
    await _client.from('rooms').update({
      'timer_end_at': endAt.toIso8601String(),
      'status': 'voting',
    }).eq('id', roomId);
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _client.from('rooms').stream(primaryKey: ['id']).eq('id', roomId).map((data) {
      return RoomModel.fromJson(data.first);
    });
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _client.from('rooms').update({'status': status.name}).eq('id', roomId);
  }

  Future<void> updateRoomSettings(String roomId, {bool? isPrivate, int? matchThreshold}) async {
    final updates = <String, dynamic>{};
    if (isPrivate != null) updates['is_private'] = isPrivate;
    if (matchThreshold != null) updates['match_threshold'] = RoomModel.thresholdToDbValue(matchThreshold);
    if (updates.isNotEmpty) {
      await _client.from('rooms').update(updates).eq('id', roomId);
    }
  }

  Future<void> updateTimerDuration(String roomId, Duration duration) async {
    final endAt = DateTime.now().add(duration);
    await _client.from('rooms').update({
      'timer_end_at': endAt.toIso8601String(),
    }).eq('id', roomId);
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
  }
}
