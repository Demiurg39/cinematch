import 'package:cinematch/env_config.dart';

class AppConstants {
  AppConstants._();

  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  static String get tmdbApiKey => EnvConfig.tmdbApiKey;
}