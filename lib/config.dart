import 'package:supabase_flutter/supabase_flutter.dart';

/// Values build time par --dart-define se aate hain (GitHub Secrets se).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  // Google Cloud Console ka "Web application" OAuth client ID
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
}

SupabaseClient get supabase => Supabase.instance.client;
