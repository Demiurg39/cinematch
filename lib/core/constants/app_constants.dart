import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cinematch/env_config.dart';

class AppConstants {
  AppConstants._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? EnvConfig.supabaseAnonKey;
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? EnvConfig.tmdbApiKey;
  static String get supabaseProjectRef => dotenv.env['SUPABASE_PROJECT_REF'] ?? EnvConfig.supabaseProjectRef;
}