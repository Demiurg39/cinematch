# Cinematch Phase 9: Extras

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Settings screen, user profile screen, notification preferences, app theme toggle (dark/light), about screen.

**Architecture:** User settings stored in `user_settings` table + local SharedPreferences for theme. Notifications via Supabase Realtime.

**Tech Stack:** flutter_riverpod, SharedPreferences, Supabase Postgres

---

## File Structure

```
lib/features/settings/
├── data/
│   └── settings_repository.dart    # User settings CRUD
└── presentation/
    ├── settings_screen.dart         # Settings list
    ├── profile_screen.dart          # User profile
    └── providers/
        └── settings_provider.dart   # Settings state
```

---

## Tasks

### Task 1: Settings Repository

**Files:**
- Create: `lib/features/settings/data/settings_repository.dart`

- [ ] **Step 1: Create settings_repository.dart**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    if (updates.isEmpty) return;

    await _supabase.from('user_settings').upsert({
      'user_id': userId,
      ...updates,
    });
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('dark_mode') ?? true; // Default dark
  }

  Future<void> setThemeMode(bool darkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', darkMode);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/data/settings_repository.dart && git commit -m "feat: add SettingsRepository"
```

---

### Task 2: Settings Provider

**Files:**
- Create: `lib/features/settings/presentation/providers/settings_provider.dart`

- [ ] **Step 1: Create settings_provider.dart**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/settings_repository.dart';

part 'settings_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository();
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<Map<String, dynamic>> build() async {
    return ref.read(settingsRepositoryProvider).getUserSettings();
  }

  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? matchNotifications,
    bool? partnerNotifications,
    bool? friendNotifications,
    String? preferredLanguage,
    String? region,
  }) async {
    await ref.read(settingsRepositoryProvider).updateUserSettings(
      notificationsEnabled: notificationsEnabled,
      matchNotifications: matchNotifications,
      partnerNotifications: partnerNotifications,
      friendNotifications: friendNotifications,
      preferredLanguage: preferredLanguage,
      region: region,
    );
    ref.invalidateSelf();
  }
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<bool> build() async {
    return ref.read(settingsRepositoryProvider).getThemeMode();
  }

  Future<void> toggleTheme() async {
    final current = state.valueOrNull ?? true;
    await ref.read(settingsRepositoryProvider).setThemeMode(!current);
    state = AsyncData(!current);
  }
}
```

- [ ] **Step 2: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/ && git commit -m "feat: add settings providers"
```

---

### Task 3: Settings Screen

**Files:**
- Create: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Step 1: Create settings_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final isDark = ref.watch(themeModeNotifierProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications'),
                value: settings['notifications_enabled'] as bool? ?? true,
                onChanged: (value) => ref.read(settingsNotifierProvider.notifier).updateSettings(
                  notificationsEnabled: value,
                ),
              ),
              SwitchListTile(
                title: const Text('Match Notifications'),
                subtitle: const Text('Notify when you match on a movie'),
                value: settings['match_notifications'] as bool? ?? true,
                onChanged: (value) => ref.read(settingsNotifierProvider.notifier).updateSettings(
                  matchNotifications: value,
                ),
              ),
              SwitchListTile(
                title: const Text('Partner Notifications'),
                subtitle: const Text('Notify for partner activity'),
                value: settings['partner_notifications'] as bool? ?? true,
                onChanged: (value) => ref.read(settingsNotifierProvider.notifier).updateSettings(
                  partnerNotifications: value,
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: isDark,
                onChanged: (_) => ref.read(themeModeNotifierProvider.notifier).toggleTheme(),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart && git commit -m "feat: add SettingsScreen"
```

---

### Task 4: Profile Screen

**Files:**
- Create: `lib/features/settings/presentation/profile_screen.dart`

- [ ] **Step 1: Create profile_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Not logged in'));
          }
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: Text(
                  user.username[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(user.username, style: const TextStyle(fontSize: 24))),
              const SizedBox(height: 8),
              Center(child: Text(user.email ?? '', style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Username'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Preferred Language'),
                subtitle: Text(user.preferredLanguage ?? 'Not set'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Region'),
                subtitle: Text(user.region ?? 'Not set'),
                onTap: () {},
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/presentation/profile_screen.dart && git commit -m "feat: add ProfileScreen"
```

---

## Self-Review

- [x] SettingsRepository with user settings + theme
- [x] SettingsNotifier + ThemeModeNotifier
- [x] SettingsScreen with notifications + theme toggle
- [x] ProfileScreen with user info + sign out
- [ ] Next: Integration with app navigation

**Plan complete and saved to `docs/superpowers/plans/2026-05-09-phase-9-extras.md`**
