import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/swipe/presentation/swipe_screen.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import '../features/friends/presentation/social_hub_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/users/presentation/providers/presence_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _screens = const [
    SwipeScreen(),
    RoomsScreen(),
    SocialHubScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set online on app start
    Future.microtask(() => ref.read(myPresenceNotifierProvider.notifier).setOnline());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ref.read(myPresenceNotifierProvider.notifier).setOnline();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(myPresenceNotifierProvider.notifier).setOffline();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize presence tracking
    ref.watch(myPresenceNotifierProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swipe_rounded),
            selectedIcon: Icon(Icons.swipe_rounded),
            label: 'Swipe',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}