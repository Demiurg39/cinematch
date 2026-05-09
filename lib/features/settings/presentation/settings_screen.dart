import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/settings_provider.dart';
import 'profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This section is under construction.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final isDarkAsync = ref.watch(themeModeNotifierProvider);
    final isDark = isDarkAsync.valueOrNull ?? true;

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
              const ListTile(
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoonDialog(context),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoonDialog(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
