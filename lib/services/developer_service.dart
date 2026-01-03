import 'package:supabase_flutter/supabase_flutter.dart';

class DeveloperService {
  final supabase = Supabase.instance.client;

  // -----------------------------
  // FETCH ALL DEVELOPERS
  // -----------------------------
  Future<List<Map<String, dynamic>>> fetchDevelopers() async {
    final res = await supabase
        .from('developers')
        .select()
        .order('created_at', ascending: false);

    if (res == null) return [];
    return List<Map<String, dynamic>>.from(res);
  }

  // -----------------------------
  // ADD DEVELOPER
  // -----------------------------
  Future<bool> addDeveloper(Map<String, dynamic> data) async {
    try {
      await supabase.from('developers').insert(data);
      return true;
    } catch (e) {
      print("ADD ERROR: $e");
      return false;
    }
  }

  // -----------------------------
  // UPDATE DEVELOPER
  // -----------------------------
  Future<bool> updateDeveloper(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('developers').update(data).eq('id', id);
      return true;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return false;
    }
  }

  // -----------------------------
  // AUTO UPDATE STATUS (Expired)
  // -----------------------------
  Future<void> autoUpdateExpiredDevelopers() async {
    try {
      final today = DateTime.now();

      final res = await supabase.from('developers').select();
      if (res == null) return;

      for (final dev in res) {
        final expStr = dev['subscription_expiry_date'];
        if (expStr == null) continue;

        final expiry = DateTime.tryParse(expStr);
        if (expiry != null && expiry.isBefore(today)) {
          await supabase
              .from('developers')
              .update({'status': 'Expired'})
              .eq('id', dev['id']);
        }
      }
    } catch (e) {
      print("AUTO STATUS ERROR: $e");
    }
  }

  // -----------------------------
  // FETCH PENDING OWNER REQUESTS
  // -----------------------------
  Future<List<Map<String, dynamic>>> fetchOwnerRequests() async {
    final res = await supabase
        .from('owner_requests')
        .select()
        .order('created_at', ascending: false);

    if (res == null) return [];
    return List<Map<String, dynamic>>.from(res);
  }

  // -----------------------------
  // APPROVE OR REJECT OWNER
  // -----------------------------
  Future<bool> handleOwnerApproval(int ownerId, bool approve) async {
    try {
      await supabase.rpc('approve_owner', params: {'owner_id': ownerId, 'approve': approve});
      return true;
    } catch (e) {
      print("APPROVAL ERROR: $e");
      return false;
    }
  }

  // -----------------------------
  // AUTO UPDATE EXPIRED
  // -----------------------------
  Future<void> autoUpdateExpiredOwners() async {
    try {
      await supabase.rpc('auto_update_owner_expiry');
    } catch (e) {
      print("AUTO EXPIRED ERROR: $e");
    }
  }

}
