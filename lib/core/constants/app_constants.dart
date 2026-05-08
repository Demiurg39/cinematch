import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get tmdbApiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  static String get supabaseProjectRef => dotenv.env['SUPABASE_PROJECT_REF'] ?? '';
}