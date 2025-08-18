import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xdntvwflpsrcwgtncndh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkbnR2d2ZscHNyY3dndG5jbmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwOTIxNDYsImV4cCI6MjA3MDY2ODE0Nn0.Lp9TJAKuhdpmxmvdDbd0GqF-k0pZRAipMm_GfPa8ieQ';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
