import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/rooms/domain/room_model.dart';

void main() {
  group('RoomModel', () {
    test('fromJson creates RoomModel correctly', () {
      final json = {
        'id': 'room-123',
        'code': 'ABC123',
        'name': 'Test Room',
        'created_by': 'user-456',
        'status': 'lobby',
        'match_threshold': 2,
        'created_at': '2024-01-01T00:00:00.000Z',
        'participant_ids': ['user-1', 'user-2'],
      };

      final room = RoomModel.fromJson(json);

      expect(room.id, 'room-123');
      expect(room.code, 'ABC123');
      expect(room.name, 'Test Room');
      expect(room.status, RoomStatus.lobby);
      expect(room.matchThreshold, 2);
      expect(room.participantIds.length, 2);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'room-123',
        'code': 'ABC123',
        'name': 'Test Room',
        'created_by': 'user-456',
        'status': 'voting',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final room = RoomModel.fromJson(json);

      expect(room.id, 'room-123');
      expect(room.status, RoomStatus.voting);
      expect(room.matchThreshold, 2);
      expect(room.participantIds, isEmpty);
    });

    test('toJson creates correct map', () {
      final room = RoomModel(
        id: 'room-123',
        code: 'ABC123',
        name: 'Test Room',
        createdBy: 'user-456',
        status: RoomStatus.matched,
        matchThreshold: 3,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        participantIds: const ['user-1'],
      );

      final json = room.toJson();

      expect(json['id'], 'room-123');
      expect(json['code'], 'ABC123');
      expect(json['name'], 'Test Room');
      expect(json['status'], 'matched');
      expect(json['match_threshold'], 3);
    });
  });
}
