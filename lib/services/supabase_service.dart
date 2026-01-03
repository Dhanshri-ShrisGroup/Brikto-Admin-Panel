import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://gzxzaxdkbuicjpzttlwb.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6eHpheGRrYnVpY2pwenR0bHdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNzE3NTIsImV4cCI6MjA4MTY0Nzc1Mn0.otrGL1_pw243sZFPzCVhi7nuRzkImmxOX2fmieYJMec',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
