import 'package:flutter_test/flutter_test.dart';
import 'package:cinematch/features/auth/domain/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates UserModel correctly', () {
      final json = {
        'id': 'user-123',
        'username': 'testuser',
        'avatar_url': 'https://example.com/avatar.jpg',
        'preferred_language': 'en',
        'region': 'US',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.username, 'testuser');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.preferredLanguage, 'en');
      expect(user.region, 'US');
      expect(user.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user-123',
        'username': 'testuser',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.username, 'testuser');
      expect(user.avatarUrl, null);
      expect(user.preferredLanguage, 'en');
      expect(user.region, 'US');
    });

    test('toJson creates correct map', () {
      final user = UserModel(
        id: 'user-123',
        username: 'testuser',
        avatarUrl: 'https://example.com/avatar.jpg',
        preferredLanguage: 'en',
        region: 'US',
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final json = user.toJson();

      expect(json['id'], 'user-123');
      expect(json['username'], 'testuser');
      expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      expect(json['preferred_language'], 'en');
      expect(json['region'], 'US');
      expect(json['created_at'], '2024-01-01T00:00:00.000Z');
    });
  });
}
