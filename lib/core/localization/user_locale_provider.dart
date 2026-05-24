import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class UserLocale {
  final String language;
  final String region;

  const UserLocale({this.language = 'en', this.region = 'US'});

  String get languageTag => '$language-${region.toUpperCase()}';

  UserLocale copyWith({String? language, String? region}) {
    return UserLocale(
      language: language ?? this.language,
      region: region ?? this.region,
    );
  }
}

final userLocaleProvider = Provider<UserLocale>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState case AuthAuthenticated(:final user)) {
    return UserLocale(
      language: user.preferredLanguage,
      region: user.region,
    );
  }
  return const UserLocale();
});