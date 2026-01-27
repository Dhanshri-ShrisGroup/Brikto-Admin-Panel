import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/sidebar.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  final _supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> sites = [];
  int? ownerId;

  final List<String> siteStatusOptions = [
    'planning',
    'active',
    'on_hold',
    'completed'
  ];


List<Map<String, dynamic>> approvedSites = [];
List<Map<String, dynamic>> siteRequests = [];

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: const Navbar(title: 'Site Management'),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Approved Sites'),
                    Tab(text: 'Site Requests'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildApprovedSites(),
                      _buildSiteRequests(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> fetchSites() async {
  setState(() => loading = true);

  if (ownerId == null) {
    setState(() => loading = false);
    return;
  }

  try {
    final res = await _supabase
        .from('sites')
        .select()
        .eq('owner_id', ownerId!)
        .order('id', ascending: false);

    final all = List<Map<String, dynamic>>.from(res);

    approvedSites =
        all.where((s) => s['is_approved'] == true).toList();

    siteRequests =
        all.where((s) => s['is_approved'] != true).toList();
  } catch (e) {
    debugPrint('fetchSites error: $e');
    approvedSites = [];
    siteRequests = [];
  } finally {
    setState(() => loading = false);
  }
}

 @override
void didChangeDependencies() {
  super.didChangeDependencies();

  final args = ModalRoute.of(context)?.settings.arguments;

  if (args is Map) {
    final dynamic v = args['ownerId'] ?? args['developerId'];
    if (v is int) ownerId = v;
    else if (v is String) ownerId = int.tryParse(v);
  }

  // 🚨 If refresh happened → redirect
  if (ownerId == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/developers');
    });
    return;
  }

  fetchSites();
}

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  // Future<void> fetchSites() async {
  //   setState(() => loading = true);

Widget _buildApprovedSites() {
  if (loading) return const LoadingIndicator();
  if (approvedSites.isEmpty) {
    return const Center(child: Text('No approved sites'));
  }

  return ListView.builder(
    padding: const EdgeInsets.all(AppSizes.defaultPadding),
    itemCount: approvedSites.length,
    itemBuilder: (_, i) {
      final s = approvedSites[i];
      return Card(
        child: ListTile(
          title: Text(s['name']),
          subtitle: Text(s['location'] ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => showSiteForm(site: s),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => deleteSite(s['id']),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget _buildSiteRequests() {
  if (loading) return const LoadingIndicator();
  if (siteRequests.isEmpty) {
    return const Center(child: Text('No site requests'));
  }

  return ListView.builder(
    padding: const EdgeInsets.all(AppSizes.defaultPadding),
    itemCount: siteRequests.length,
    itemBuilder: (_, i) {
      final s = siteRequests[i];
      return Card(
        child: ListTile(
          title: Text(s['name']),
          subtitle: Text(
            '${s['location']} • ${s['project_type'] ?? ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Approve',
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => approveSite(s['id']),
              ),
              IconButton(
                tooltip: 'Reject',
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => rejectSite(s['id']),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Future<void> approveSite(int siteId) async {
  try {
    await _supabase.rpc('approve_site', params: {
      'p_site_id': siteId,
    });
    fetchSites();
  } catch (e) {
    debugPrint('approveSite error: $e');
  }
}

Future<void> rejectSite(int siteId) async {
  try {
    await _supabase.rpc('reject_site', params: {
      'p_site_id': siteId,
    });
    fetchSites();
  } catch (e) {
    debugPrint('rejectSite error: $e');
  }
}



  //   if (ownerId == null) {
  //     setState(() {
  //       loading = false;
  //       sites = [];
  //     });
  //     return;
  //   }

  //   try {
  //     final response = await _supabase
  //         .from('sites')
  //         .select()
  //         .eq('owner_id', ownerId!)
  //         .order('id', ascending: false);

  //     sites = response
  //         .map<Map<String, dynamic>>(
  //             (e) => Map<String, dynamic>.from(e))
  //         .toList();
  //   } catch (e) {
  //     debugPrint('fetchSites error: $e');
  //     sites = [];
  //   } finally {
  //     setState(() => loading = false);
  //   }
  // }

  Future<void> deleteSite(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete site?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('sites').delete().eq('id', id);
      fetchSites();
    } catch (e) {
      debugPrint('deleteSite error: $e');
    }
  }

  Future<void> toggleIsActive(Map<String, dynamic> site) async {
    try {
      final newVal = !(site['is_active'] == true);
      await _supabase
          .from('sites')
          .update({'is_active': newVal})
          .eq('id', site['id']);
      fetchSites();
    } catch (e) {
      debugPrint('toggleIsActive error: $e');
    }
  }

void showSiteForm({Map<String, dynamic>? site}) {
  if (ownerId == null) return;
  final int developerId = ownerId!;

  final nameCtrl = TextEditingController(text: site?['name'] ?? '');
  final locationCtrl = TextEditingController(text: site?['location'] ?? '');
  final descCtrl = TextEditingController(text: site?['description'] ?? '');

  String status = site?['status'] ?? siteStatusOptions.first;

  DateTime? startDate = _parseDate(site?['start_date']);
  DateTime? endDate = _parseDate(site?['end_date']);

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSB) {
        final startText = TextEditingController(
            text: startDate?.toIso8601String().split('T')[0] ?? '');
        final endText = TextEditingController(
            text: endDate?.toIso8601String().split('T')[0] ?? '');

        return AlertDialog(
          title: Text(site == null ? 'Add Site' : 'Edit Site'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Site Name'),
                ),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: siteStatusOptions
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setSB(() => status = v!),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextFormField(
                  readOnly: true,
                  controller: startText,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSB(() {
                        startDate = picked;
                        startText.text =
                            picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),
                TextFormField(
                  readOnly: true,
                  controller: endText,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSB(() {
                        endDate = picked;
                        endText.text =
                            picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Start date and End date are required')),
                  );
                  return;
                }

                final payload = {
                  'owner_id': developerId,
                  'name': nameCtrl.text.trim(),
                  'location': locationCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'status': status,
                  'start_date':
                      startDate!.toIso8601String().split('T')[0],
                  'end_date':
                      endDate!.toIso8601String().split('T')[0],
                };

                if (site == null) {
                  await _supabase.from('sites').insert(payload);
                } else {
                  await _supabase
                      .from('sites')
                      .update(payload)
                      .eq('id', site['id']);
                }

                Navigator.pop(context);
                fetchSites();
              },
            ),
          ],
        );
      },
    ),
  );
}

  // @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: const Navbar(title: 'Site Management'),
//       body: Row(
//         children: [
//           const Sidebar(),
//           Expanded(
//             child: loading
//                 ? const LoadingIndicator()
//                 : sites.isEmpty
//                     ? const Center(child: Text('No sites found'))
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(AppSizes.defaultPadding),
//                         itemCount: sites.length,
//                         itemBuilder: (_, i) {
//                           final s = sites[i];
//                           return Card(
//                             child: ListTile(
//                               title: Text(s['name']),
//                               subtitle: Text(s['location'] ?? ''),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   IconButton(
//                                       icon: const Icon(Icons.edit),
//                                       onPressed: () => showSiteForm(site: s)),
//                                   IconButton(
//                                       icon: const Icon(Icons.delete),
//                                       onPressed: () => deleteSite(s['id'])),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//           ),
//         ],
//       ),
//     );
//   }
}