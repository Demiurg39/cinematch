/// Environment configuration - used as fallback when .env file is not available.
/// Replace these values with your actual credentials.
class EnvConfig {
  EnvConfig._();

  /// Supabase project URL
  static const String supabaseUrl = 'https://ixpuxpwssvkjqvfylfbt.supabase.co';

  /// Supabase anonymous/public key
  static const String supabaseAnonKey = '';

  /// TMDB API key
  static const String tmdbApiKey = '';
}
