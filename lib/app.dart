import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'app/app_shell.dart';

class CinematchApp extends ConsumerStatefulWidget {
  final ColorScheme? dynamicDarkScheme;

  const CinematchApp({super.key, this.dynamicDarkScheme});

  @override
  ConsumerState<CinematchApp> createState() => _CinematchAppState();
}

class _CinematchAppState extends ConsumerState<CinematchApp> {
  bool _sessionCheckDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionCheckDone) {
      _sessionCheckDone = true;
      Future.microtask(() {
        ref.read(authNotifierProvider.notifier).restoreSession();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'Cinematch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.amoledDark(widget.dynamicDarkScheme),
      darkTheme: AppTheme.amoledDark(widget.dynamicDarkScheme),
      themeMode: ThemeMode.dark,
      home: ref.watch(authNotifierProvider).when<Widget>(
        loading: () => const AuthScreen(),
        error: (_, __) => const AuthScreen(),
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