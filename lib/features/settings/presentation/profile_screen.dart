import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
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
                onTap: () => _showEditUsernameDialog(context, ref, user.username),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Preferred Language'),
                subtitle: Text(user.preferredLanguage),
                onTap: () => _showEditLanguageDialog(context, ref, user.preferredLanguage),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Region'),
                subtitle: Text(user.region),
                onTap: () => _showEditRegionDialog(context, ref, user.region),
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isNotEmpty && newUsername != currentUsername) {
                final repo = AuthRepository();
                await repo.updateUser(username: newUsername);
                ref.invalidate(authNotifierProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLanguageDialog(BuildContext context, WidgetRef ref, String currentLanguage) {
    final languages = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferred Language'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (_, index) {
              final lang = languages[index];
              return ListTile(
                title: Text(lang.toUpperCase()),
                trailing: lang == currentLanguage ? const Icon(Icons.check) : null,
                onTap: () async {
                  final repo = AuthRepository();
                  await repo.updateUser(preferredLanguage: lang);
                  ref.invalidate(authNotifierProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEditRegionDialog(BuildContext context, WidgetRef ref, String currentRegion) {
    final regions = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'JP', 'KR', 'BR'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Region'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: regions.length,
            itemBuilder: (_, index) {
              final region = regions[index];
              return ListTile(
                title: Text(region),
                trailing: region == currentRegion ? const Icon(Icons.check) : null,
                onTap: () async {
                  final repo = AuthRepository();
                  await repo.updateUser(region: region);
                  ref.invalidate(authNotifierProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
