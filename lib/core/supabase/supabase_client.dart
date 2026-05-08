import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class AppSupabaseClient {
  AppSupabaseClient._();

  static final AppSupabaseClient instance = AppSupabaseClient._();

  late final Supabase _supabase;

  void init() {
    _supabase = Supabase.instance;
  }

  Supabase get supabase => _supabase;

  AuthClient get auth => _supabase.auth;
  PostgresClient get postgrest => _supabase.postgrest;
  RealtimeClient get realtime => _supabase.realtime;
  StorageClient get storage => _supabase.storage;
  FunctionsClient get functions => _supabase.functions;
}
