import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClient _supabase;
  SettingsRepository({SupabaseClient? supabase}) : _supabase = supabase ?? Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>> getUserSettings() async {
    final userId = currentUserId;
    if (userId == null) return {};

    final response = await _supabase.from('user_settings').select().eq('user_id', userId).maybeSingle();
    return response ?? {};
  }

  Future<void> updateUserSettings({
    bool? notificationsEnabled,
    bool? matchNotifications,
    bool? partnerNotifications,
    bool? friendNotifications,
    String? preferredLanguage,
    String? region,
    bool? darkMode,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (notificationsEnabled != null) updates['notifications_enabled'] = notificationsEnabled;
    if (matchNotifications != null) updates['match_notifications'] = matchNotifications;
    if (partnerNotifications != null) updates['partner_notifications'] = partnerNotifications;
    if (friendNotifications != null) updates['friend_notifications'] = friendNotifications;
    if (preferredLanguage != null) updates['preferred_language'] = preferredLanguage;
    if (region != null) updates['region'] = region;
    if (darkMode != null) updates['dark_mode'] = darkMode;

    if (updates.isEmpty) return;

    await _supabase.from('user_settings').upsert({
      'user_id': userId,
      ...updates,
    });
  }
}
