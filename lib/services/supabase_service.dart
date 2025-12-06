import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://kkwbwxvydebtueopreqo.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtrd2J3eHZ5ZGVidHVlb3ByZXFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3ODI2MDIsImV4cCI6MjA4MDM1ODYwMn0.dmVeneXFsRbkiVkFjNSRfKQdpwn0i4s4a1N7EaAXBOE',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
