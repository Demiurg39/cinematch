import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSessionService {
  final FlutterSecureStorage _storage;

  AuthSessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'supabase_session';
  static const _userIdKey = 'cached_user_id';

  Future<void> saveSession(Session session) async {
    await _storage.write(key: _sessionKey, value: session.toJson().toString());
    await _storage.write(key: _userIdKey, value: session.user.id);
  }

  Future<String?> getCachedUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _userIdKey);
  }

  Future<bool> hasSession() async {
    final session = await _storage.read(key: _sessionKey);
    final userId = await _storage.read(key: _userIdKey);
    return session != null && userId != null;
  }
}