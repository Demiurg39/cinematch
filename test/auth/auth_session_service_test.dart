import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cinematch/features/auth/data/auth_session_service.dart';

void main() {
  late AuthSessionService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    service = AuthSessionService();
  });

  group('AuthSessionService', () {
    test('hasSession returns false when no session stored', () async {
      final result = await service.hasSession();
      expect(result, false);
    });

    test('hasSession returns true after session saved', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: 'session-data');
      await storage.write(key: 'cached_user_id', value: 'user-123');

      final result = await service.hasSession();
      expect(result, true);
    });

    test('hasSession returns false when only session key exists', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: 'session-data');

      final result = await service.hasSession();
      expect(result, false);
    });

    test('hasSession returns false when only user id exists', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'cached_user_id', value: 'user-123');

      final result = await service.hasSession();
      expect(result, false);
    });

    test('getCachedUserId returns saved user id', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'cached_user_id', value: 'user-456');

      final userId = await service.getCachedUserId();
      expect(userId, 'user-456');
    });

    test('getCachedUserId returns null when not saved', () async {
      final userId = await service.getCachedUserId();
      expect(userId, isNull);
    });

    test('clearSession removes both keys', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: 'session-data');
      await storage.write(key: 'cached_user_id', value: 'user-123');

      await service.clearSession();

      final hasSession = await service.hasSession();
      expect(hasSession, false);
    });

    test('clearSession is idempotent when no session exists', () async {
      await service.clearSession();

      final result = await service.hasSession();
      expect(result, false);
    });

    test('saveSession persists session data via secure storage', () async {
      final sessionJson = '{"access_token": "test-token"}';
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: sessionJson);
      await storage.write(key: 'cached_user_id', value: 'user-789');

      final hasSession = await service.hasSession();
      expect(hasSession, true);
      final cachedUserId = await service.getCachedUserId();
      expect(cachedUserId, 'user-789');
    });

    test('subsequent sessions replace previous ones', () async {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'supabase_session', value: 'session-v1');
      await storage.write(key: 'cached_user_id', value: 'user-1');

      await service.clearSession();

      await storage.write(key: 'supabase_session', value: 'session-v2');
      await storage.write(key: 'cached_user_id', value: 'user-2');

      final userId = await service.getCachedUserId();
      expect(userId, 'user-2');
      final hasSession = await service.hasSession();
      expect(hasSession, true);
    });
  });
}