import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    bool? darkMode,
  }) async {
    await ref.read(settingsRepositoryProvider).updateUserSettings(
      notificationsEnabled: notificationsEnabled,
      matchNotifications: matchNotifications,
      partnerNotifications: partnerNotifications,
      friendNotifications: friendNotifications,
      preferredLanguage: preferredLanguage,
      region: region,
      darkMode: darkMode,
    );
    ref.invalidateSelf();
  }
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<bool> build() async {
    final settings = await ref.read(settingsRepositoryProvider).getUserSettings();
    return settings['dark_mode'] as bool? ?? true;
  }

  Future<void> toggleTheme() async {
    final current = state.valueOrNull ?? true;
    await ref.read(settingsRepositoryProvider).updateUserSettings(darkMode: !current);
    state = AsyncData(!current);
  }
}
