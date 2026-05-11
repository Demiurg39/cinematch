import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/room_model.dart';

class RoomsRepository {
  final SupabaseClient _client;
  RoomsRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<RoomModel> createRoom({
    required String name,
    required int matchThreshold,
  }) async {
    final code = _generateRoomCode();
    final userId = currentUserId!;

    final response = await _client.from('rooms').insert({
      'code': code,
      'name': name,
      'created_by': userId,
      'status': 'active',
      'match_threshold': 'half',
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
    // Get rooms through room_members junction table
    final roomIds = await _client.from('room_members')
        .select('room_id')
        .eq('user_id', userId);

    if (roomIds.isEmpty) return [];

    final roomIdList = roomIds.map((r) => r['room_id'] as String).toList();
    final allRooms = await _client.from('rooms').select();
    final response = allRooms.where((json) => roomIdList.contains(json['id'] as String)).toList();
    return response.map((json) => RoomModel.fromJson(json)).toList();
  }

  Stream<RoomModel> watchRoom(String roomId) {
    return _client.from('rooms').stream(primaryKey: ['id']).eq('id', roomId).map((data) {
      return RoomModel.fromJson(data.first);
    });
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _client.from('rooms').update({'status': status.name}).eq('id', roomId);
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(now ~/ (i + 1)) % chars.length]).join();
  }
}
