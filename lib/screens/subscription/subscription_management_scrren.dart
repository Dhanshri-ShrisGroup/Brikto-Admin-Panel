
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class SubscriptionManagementPage extends StatefulWidget {
//   const SubscriptionManagementPage({super.key});

//   @override
//   State<SubscriptionManagementPage> createState() =>
//       _SubscriptionManagementPageState();
// }

// class _SubscriptionManagementPageState
//     extends State<SubscriptionManagementPage> {
//   final supabase = Supabase.instance.client;

//   bool loading = true;
//   List<Map<String, dynamic>> developers = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchDevelopers();
//   }

//   Future<void> fetchDevelopers() async {
//     setState(() => loading = true);

//     final res = await supabase
//         .from('developer_subscription_view')
//         .select()
//         .order('id', ascending: false);


//     developers = List<Map<String, dynamic>>.from(res);
//     setState(() => loading = false);
//   }

//   Future<void> renewSubscription({
//     required int userId,
//     required String plan,
//     required DateTime start,
//     required DateTime expiry,
//   }) async {
//     await supabase.rpc('renew_subscription', params: {
//       'p_user_id': userId,
//       'p_plan': plan,
//       'p_start_date': start.toIso8601String(),
//       'p_expiry_date': expiry.toIso8601String(),
//       'p_note': 'Renewed by SuperAdmin',
//     });

//     fetchDevelopers();
//   }

//   Future<void> suspendUser(int userId) async {
//     await supabase.rpc('suspend_user', params: {
//       'p_user_id': userId,
//       'p_note': 'Suspended by SuperAdmin',
//     });

//     fetchDevelopers();
//   }

//   Future<void> unsuspendUser(int userId) async {
//     await supabase.rpc('unsuspend_user', params: {
//       'p_user_id': userId,
//       'p_new_status': 'Active',
//       'p_note': 'Unsuspended by SuperAdmin',
//     });

//     fetchDevelopers();
//   }

//   void openSubscriptionDialog(Map<String, dynamic> dev) {
//     String selectedPlan = dev['subscription_plan'] ?? 'Monthly';

//     DateTime startDate = DateTime.now();
//     DateTime expiryDate =
//         DateTime.now().add(const Duration(days: 30));

//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text("Manage Subscription"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<String>(
//                 value: selectedPlan,
//                 items: const [
//                   DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
//                   DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
//                   DropdownMenuItem(value: 'Custom', child: Text('Custom')),
//                 ],
//                 onChanged: (v) => selectedPlan = v!,
//                 decoration:
//                     const InputDecoration(labelText: "Plan Type"),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 child: const Text("Confirm Renewal"),
//                 onPressed: () {
//                   renewSubscription(
//                     userId: dev['id'],
//                     plan: selectedPlan,
//                     start: startDate,
//                     expiry: expiryDate,
//                   );
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Color statusColor(String status) {
//     switch (status) {
//       case 'Active':
//         return Colors.green;
//       case 'Expired':
//         return Colors.orange;
//       case 'Suspended':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar:
//           AppBar(title: const Text("Subscription Management")),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16),
//               child: ListView.builder(
//                 itemCount: developers.length,
//                 itemBuilder: (context, index) {
//                   final dev = developers[index];
//                   final status = dev['current_status'];

//                   return Card(
//                     margin:
//                         const EdgeInsets.symmetric(vertical: 8),
//                     child: ListTile(
//                       title: Text(dev['developer_name'] ?? ''),
//                       subtitle: Text(
//                         "Plan: ${dev['subscription_plan']} • "
//                         "Status: $status\n"
//                         "Expiry: ${dev['subscription_expiry_date'] ?? '-'}",
//                       ),
//                       trailing: Wrap(
//                         spacing: 8,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.refresh),
//                             tooltip: "Renew",
//                             onPressed: () =>
//                                 openSubscriptionDialog(dev),
//                           ),
//                           if (status != 'Suspended')
//                             IconButton(
//                               icon: const Icon(Icons.block),
//                               tooltip: "Suspend",
//                               onPressed: () =>
//                                   suspendUser(dev['id']),
//                             ),
//                           if (status == 'Suspended')
//                             IconButton(
//                               icon:
//                                   const Icon(Icons.check_circle),
//                               tooltip: "Unsuspend",
//                               onPressed: () =>
//                                   unsuspendUser(dev['id']),
//                             ),
//                         ],
//                       ),
//                       leading: Icon(
//                         Icons.circle,
//                         color: statusColor(status),
//                         size: 14,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/sidebar.dart';
import '../../core/widgets/loader.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}
final List<String> subscriptionStatusOptions = [
  'Active',
  'Inactive',
  'Expired',
  'Suspended',
];
final List<String> filterOptions = [
  'All',
  'Active',
  'Inactive',
  'Expired',
  'Suspended',
];


class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> developers = [];
  String filter = 'All'; // Active, Expired, Suspended, All

  @override
  void initState() {
    super.initState();
    fetchDevelopers();
  }

  Future<void> fetchDevelopers() async {
    setState(() => loading = true);
    try {
      final res =
          await supabase.from('developer_subscription_view').select(); // use your view
      developers = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("Fetch error: $e");
      developers = [];
    }
    setState(() => loading = false);
  }
  // ---------------- DATE NORMALIZER ----------------
  String? normalizeDate(String value) {
    if (value.trim().isEmpty) return null;
    return value;
}

// ---------------- FILTER ----------------
  List<Map<String, dynamic>> get filteredDevelopers {
    if (filter == 'All') return developers;
    return developers.where((d) => d['current_status'] == filter).toList();
  }
 // ---------------- SUBSCRIPTION DIALOG ----------------
  void showSubscriptionDialog(Map<String, dynamic> dev, {bool renew = false}) {
    final planController =
        TextEditingController(text: dev['subscription_plan'] ?? 'Monthly');
    final startController =
        TextEditingController(text: dev['subscription_start_date'] ?? '');
    final endController =
        TextEditingController(text: dev['subscription_expiry_date'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(renew ? "Renew Subscription" : "Change Subscription"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: planController.text,
                items: ['Monthly', 'Yearly', 'Custom']
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => planController.text = v!,
                decoration:
                    const InputDecoration(labelText: "Plan Type"),
              ),
              TextField(
                controller: startController,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: "Start Date (YYYY-MM-DD)"),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(startController.text) ??
                            DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    startController.text =
                        picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              TextField(
                controller: endController,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: "Expiry Date (YYYY-MM-DD)"),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(endController.text) ??
                            DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    endController.text =
                        picked.toIso8601String().split('T')[0];
                  }
                },
              ),
              TextFormField(
                initialValue: dev['current_status'],
                readOnly: true,
                decoration:
                    const InputDecoration(labelText: "Status"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            child: const Icon(Icons.save),
            onPressed: () async {
              try {
                final params = {
  'p_user_id': dev['id'],
  'p_plan': planController.text,
  'p_start_date': normalizeDate(startController.text),
  'p_expiry_date': normalizeDate(endController.text),
  'p_note': renew
      ? 'Renewed by SuperAdmin'
      : 'Changed by SuperAdmin',
};


                if (renew) {
                  await supabase.rpc(
                      'renew_subscription',
                      params: params);
                } else {
                  await supabase.rpc(
                      'change_subscription',
                      params: params);
                }

                Navigator.pop(context);
                fetchDevelopers();
              } catch (e) {
                debugPrint("Update error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("$e")));
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- SUSPEND / UNSUSPEND ----------------
  Future<void> suspendUnsuspend(Map<String, dynamic> dev) async {
    final status = dev['current_status'];

    try {
      if (status == 'Suspended') {
        await supabase.rpc('unsuspend_user',
            params: {'p_user_id': dev['id']});
      } else {
        await supabase.rpc('suspend_user',
            params: {'p_user_id': dev['id']});
      }
      fetchDevelopers();
    } catch (e) {
      debugPrint("Suspend error: $e");
    }
  }
  
  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const Navbar(title: "Subscription Management"),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(AppSizes.defaultPadding),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("Filter: "),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: filter,
                        items: filterOptions
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => filter = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: loading
                        ? const LoadingIndicator()
                        : ListView.builder(
                            itemCount:
                                filteredDevelopers.length,
                            itemBuilder: (_, i) {
                              final dev =
                                  filteredDevelopers[i];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                      dev['developer_name'] ??
                                          ''),
                                  subtitle: Text(
                                      "Plan: ${dev['subscription_plan']} • Status: ${dev['current_status']}"),
                                  trailing: Wrap(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.autorenew),
                                        onPressed: () =>
                                            showSubscriptionDialog(
                                                dev,
                                                renew: true),
                                      ),
                                      IconButton(
                                        icon:
                                            const Icon(Icons.edit),
                                        onPressed: () =>
                                            showSubscriptionDialog(
                                                dev),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            dev['current_status'] ==
                                                    'Suspended'
                                                ? Icons.lock_open
                                                : Icons.lock),
                                        onPressed: () =>
                                            suspendUnsuspend(
                                                dev),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}