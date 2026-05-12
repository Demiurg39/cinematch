import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'app/app_shell.dart';

class CinematchApp extends ConsumerWidget {
  const CinematchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme always dark for now
    ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Cinematch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: ref.watch(authNotifierProvider).when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        data: (state) {
          if (state is AuthAuthenticated) {
            return const AppShell();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}