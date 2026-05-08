import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance;

  Future<UserModel?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final userId = session.user.id;
    final response = await _supabase.postgrest
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  Stream<UserModel?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((event) async {
      final session = event.session;
      if (session == null) return null;

      final userId = session.user.id;
      final response = await _supabase.postgrest
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    }).asyncMap((future) => future);
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = response.user!.id;
    final userResponse = await _supabase.postgrest
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(userResponse);
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final userId = response.user!.id;

    // Create user profile
    await _supabase.postgrest.from('users').insert({
      'id': userId,
      'username': username,
    });

    final userResponse = await _supabase.postgrest
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(userResponse);
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> updateUser({
    String? username,
    String? avatarUrl,
    String? preferredLanguage,
    String? region,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final updates = <String, dynamic>{};

    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (preferredLanguage != null) {
      updates['preferred_language'] = preferredLanguage;
    }
    if (region != null) updates['region'] = region;

    await _supabase.postgrest
        .from('users')
        .update(updates)
        .eq('id', userId);
  }
}
