import 'package:brikto_admin_panel/core/constants/api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProService {
  ProService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final response = await _client
        .from(ApiConstants.subscriptionPlans)
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createRecord(Map<String, dynamic> data) async {
    await _client.from(ApiConstants.subscriptionPlans).insert(data);
  }

  Future<void> updateRecord(dynamic id, Map<String, dynamic> data) async {
    await _client.from(ApiConstants.subscriptionPlans).update(data).eq('id', id);
  }

  Future<void> setActive(dynamic id, bool isActive) async {
    await _client
        .from(ApiConstants.subscriptionPlans)
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<void> deleteRecord(dynamic id) async {
    await _client.from(ApiConstants.subscriptionPlans).delete().eq('id', id);
  }
}
