import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';

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
              Center(child: Text('Member since ${user.createdAt.year}', style: TextStyle(color: Colors.grey[600]))),
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
