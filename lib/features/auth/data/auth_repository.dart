import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<UserModel?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    final userId = session.user.id;
    final response = await _client.from('users').select().eq('id', userId).maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Stream<UserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) async {
      final session = event.session;
      if (session == null) return null;

      final userId = session.user.id;
      final response = await _client.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    }).asyncMap((future) => future);
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user!.id;
    var userResponse = await _client.from('users').select().eq('id', userId).maybeSingle();

    // Auto-create profile if missing (handles manually-created auth users)
    if (userResponse == null) {
      await _client.from('users').insert({'id': userId, 'username': email.split('@').first});
      userResponse = await _client.from('users').select().eq('id', userId).maybeSingle();
    }

    if (userResponse == null) {
      throw Exception('Failed to create or retrieve user profile');
    }

    return UserModel.fromJson(userResponse);
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final userId = response.user!.id;

    // Create user profile
    await _client.from('users').insert({'id': userId, 'username': username});

    final userResponse = await _client.from('users').select().eq('id', userId).maybeSingle();

    if (userResponse == null) {
      throw Exception('Failed to create user profile');
    }

    return UserModel.fromJson(userResponse);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> updateUser({
    String? username,
    String? avatarUrl,
    String? preferredLanguage,
    String? region,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final updates = <String, dynamic>{};

    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;
    if (region != null) updates['region'] = region;

    await _client.from('users').update(updates).eq('id', userId);
  }
}