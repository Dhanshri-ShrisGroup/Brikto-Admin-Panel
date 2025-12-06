import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class UserService {
  static Future<List<dynamic>> fetchUsers() async {
    final response =
        await SupabaseService.client.from('users').select('*');

    return response;
  }
}
