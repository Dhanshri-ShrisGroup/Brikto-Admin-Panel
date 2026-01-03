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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final dynamic v = args['ownerId'] ?? args['developerId'];
      if (v is int) ownerId = v;
      else if (v is String) ownerId = int.tryParse(v);
    }

    fetchSites();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Future<void> fetchSites() async {
    setState(() => loading = true);

    if (ownerId == null) {
      setState(() {
        loading = false;
        sites = [];
      });
      return;
    }

    try {
      final response = await _supabase
          .from('sites')
          .select()
          .eq('owner_id', ownerId!)
          .order('id', ascending: false);

      sites = response
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('fetchSites error: $e');
      sites = [];
    } finally {
      setState(() => loading = false);
    }
  }

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

    final nameCtrl =
        TextEditingController(text: site?['name'] ?? '');
    final locationCtrl =
        TextEditingController(text: site?['location'] ?? '');
    final descCtrl =
        TextEditingController(text: site?['description'] ?? '');
    final workerCtrl =
        TextEditingController(text: '${site?['worker_count'] ?? 0}');

    String status =
        site?['status'] ?? siteStatusOptions.first;
    double progress =
        (site?['progress'] ?? 0).toDouble();
    bool isActive = site?['is_active'] ?? true;

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
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Site Name')),
                  TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                  DropdownButtonFormField(
                    value: status,
                    items: siteStatusOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setSB(() => status = v!),
                  ),
                  Slider(
                    value: progress,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => setSB(() => progress = v),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setSB(() => isActive = v),
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
                  final payload = {
                    'owner_id': developerId,
                    'name': nameCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'status': status,
                    'progress': progress.toInt(),
                    'worker_count': int.tryParse(workerCtrl.text) ?? 0,
                    'is_active': isActive,
                    'start_date': startDate?.toIso8601String(),
                    'end_date': endDate?.toIso8601String(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const Navbar(title: 'Site Management'),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: loading
                ? const LoadingIndicator()
                : sites.isEmpty
                    ? const Center(child: Text('No sites found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.defaultPadding),
                        itemCount: sites.length,
                        itemBuilder: (_, i) {
                          final s = sites[i];
                          return Card(
                            child: ListTile(
                              title: Text(s['name']),
                              subtitle: Text(s['location'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => showSiteForm(site: s)),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => deleteSite(s['id'])),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../core/constants/colors.dart';
// import '../../core/constants/sizes.dart';
// import '../../core/widgets/loader.dart';
// import '../../core/widgets/navbar.dart';
// import '../../core/widgets/sidebar.dart';

// class SitesScreen extends StatefulWidget {
//   const SitesScreen({super.key});

//   @override
//   State<SitesScreen> createState() => _SitesScreenState();
// }

// class _SitesScreenState extends State<SitesScreen> {
//   final _supabase = Supabase.instance.client;

//   bool loading = true;
//   List<Map<String, dynamic>> sites = [];
//   int? ownerId; // This is the integer owner_id you can pass via route arguments

//   final List<String> siteStatusOptions = ['planning', 'active', 'on_hold', 'completed'];

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     // Expecting route args like: {'ownerId': 123} (integer)
//     final args = ModalRoute.of(context)?.settings.arguments;
//     if (args is Map && args['ownerId'] != null) {
//       // accept int or string convertible to int
//       final dynamic v = args['ownerId'];
//       if (v is int) ownerId = v;
//       else if (v is String) ownerId = int.tryParse(v);
//     }

//     // fetchSites is safe: if ownerId is null it fetches all sites
//     fetchSites();
//   }

//   // Helper to parse possible date fields returned by Supabase (String or DateTime)
//   DateTime? _parseDate(dynamic value) {
//     if (value == null) return null;
//     if (value is DateTime) return value;
//     try {
//       return DateTime.tryParse(value.toString());
//     } catch (_) {
//       return null;
//     }
//   }

//  Future<void> fetchSites() async {
//   setState(() => loading = true);
//   try {
//     final response = await _supabase
//         .from('sites')
//         .select()
//         .order('id', ascending: false);

//     sites = response.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
//   } catch (e) {
//     debugPrint('fetchSites error: $e');
//     sites = [];
//   } finally {
//     setState(() => loading = false);
//   }
// }

//   Future<void> deleteSite(int id) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (c) => AlertDialog(
//         title: const Text('Delete site?'),
//         content: const Text('This action cannot be undone.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
//           ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     try {
//       await _supabase.from('sites').delete().eq('id', id);
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site deleted')));
//       fetchSites();
//     } catch (e) {
//       debugPrint('deleteSite error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
//     }
//   }

//   Future<void> toggleIsActive(Map<String, dynamic> site) async {
//     try {
//       final newVal = !(site['is_active'] == true);
//       await _supabase.from('sites').update({'is_active': newVal}).eq('id', site['id']);
//       fetchSites();
//     } catch (e) {
//       debugPrint('toggleIsActive error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update site: $e')));
//     }
//   }

//   // Show Add / Edit form. If site == null => Add, else Edit
//   void showSiteForm({Map<String, dynamic>? site}) {
//     final _nameController = TextEditingController(text: site?['name']?.toString() ?? '');
//     final _locationController = TextEditingController(text: site?['location']?.toString() ?? '');
//     final _descController = TextEditingController(text: site?['description']?.toString() ?? '');
//     final _workerController = TextEditingController(text: (site?['worker_count']?.toString() ?? '0'));

//     String selectedStatus = site?['status']?.toString() ?? siteStatusOptions.first;
//     double progress = (site?['progress'] != null) ? (site!['progress'] as num).toDouble() : 0.0;
//     bool isActive = site?['is_active'] == null ? true : (site!['is_active'] == true);

//     DateTime? startDate = _parseDate(site?['start_date']);
//     DateTime? endDate = _parseDate(site?['end_date']);

//     showDialog<void>(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(builder: (context, setStateSB) {
//           // Create controllers for date text to show selected date string (not persisted)
//           final startText = TextEditingController(text: startDate != null
//     ? startDate!.toLocal().toString().split(' ')[0]
//     : '',
// );
//           final endText = TextEditingController(text: endDate != null
//     ? endDate!.toLocal().toString().split(' ')[0]
//     : '',);

//           return AlertDialog(
//             title: Text(site == null ? 'Add Site' : 'Edit Site'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: _nameController,
//                     decoration: const InputDecoration(labelText: 'Site Name'),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _locationController,
//                     decoration: const InputDecoration(labelText: 'Location / Address'),
//                   ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _descController,
//                     minLines: 2,
//                     maxLines: 4,
//                     decoration: const InputDecoration(labelText: 'Notes / Description'),
//                   ),
//                   const SizedBox(height: 12),
//                   DropdownButtonFormField<String>(
//                     value: selectedStatus,
//                     items: siteStatusOptions
//                         .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())))
//                         .toList(),
//                     onChanged: (v) => setStateSB(() => selectedStatus = v ?? selectedStatus),
//                     decoration: const InputDecoration(labelText: 'Status'),
//                   ),
//                   const SizedBox(height: 12),
//                   Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                     Text('Progress: ${progress.toInt()}%'),
//                     Slider(
//                       value: progress,
//                       min: 0,
//                       max: 100,
//                       divisions: 100,
//                       label: progress.toInt().toString(),
//                       onChanged: (v) => setStateSB(() => progress = v),
//                     ),
//                   ]),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: _workerController,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(labelText: 'Worker Count'),
//                   ),
//                   const SizedBox(height: 12),
//                   SwitchListTile(
//                     title: const Text('Active'),
//                     value: isActive,
//                     onChanged: (v) => setStateSB(() => isActive = v),
//                   ),
//                   const SizedBox(height: 12),
//                   // Start Date
//                   TextFormField(
//                     readOnly: true,
//                     controller: startText,
//                     decoration: const InputDecoration(
//                       labelText: 'Start Date',
//                       suffixIcon: Icon(Icons.calendar_today),
//                     ),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: startDate ?? DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (picked != null) {
//                         setStateSB(() {
//                           startDate = picked;
//                           startText.text = picked.toLocal().toIso8601String().split('T')[0];
//                         });
//                       }
//                     },
//                   ),
//                   const SizedBox(height: 12),
//                   // End Date
//                   TextFormField(
//                     readOnly: true,
//                     controller: endText,
//                     decoration: const InputDecoration(
//                       labelText: 'End Date',
//                       suffixIcon: Icon(Icons.calendar_today),
//                     ),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: endDate ?? DateTime.now(),
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (picked != null) {
//                         setStateSB(() {
//                           endDate = picked;
//                           endText.text = picked.toLocal().toIso8601String().split('T')[0];
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//               ElevatedButton(
//                 onPressed: () async {
//                   final name = _nameController.text.trim();
//                   if (name.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter site name')));
//                     return;
//                   }

//                   // owner_id must be provided to assign site to a developer's user account
//                   if (ownerId == null) {
//                     // If you want to require ownerId for creating sites, show an error
//                     // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No ownerId provided (owner_id). Cannot save site.')));
//                     ownerId = 2;
//                     // return;
//                   }
                  

//                   final Map<String, dynamic> payload = {
//                     'owner_id': ownerId, // integer expected by your schema
//                     'name': name,
//                     'location': _locationController.text.trim(),
//                     'description': _descController.text.trim(),
//                     'status': selectedStatus,
//                     'progress': progress.toInt(),
//                     'worker_count': int.tryParse(_workerController.text) ?? 0,
//                     'is_active': isActive,
//                     'start_date': startDate?.toIso8601String(),
//                     'end_date': endDate?.toIso8601String(),
//                   };

//                   try {
//                     if (site == null) {
//                       final insert = await _supabase.from('sites').insert(payload).select().single();
//                       // on success
//                       if (insert != null) {
//                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site added')));
//                       }
//                     } else {
//                       await _supabase.from('sites').update(payload).eq('id', site['id']);
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site updated')));
//                     }
//                     Navigator.pop(context);
//                     fetchSites();
//                   } catch (e) {
//                     debugPrint('save site error: $e');
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
//                   }
//                 },
//                 child: const Text('Save'),
//               ),
//             ],
//           );
//         });
//       },
//     );
//   }

//   @override
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
//                 : Padding(
//                     padding: const EdgeInsets.all(AppSizes.defaultPadding),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text('Sites', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                             ElevatedButton.icon(
//                               onPressed: () => showSiteForm(),
//                               icon: const Icon(Icons.add),
//                               label: const Text('Add Site'),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: AppSizes.defaultPadding),
//                         Expanded(
//                           child: sites.isEmpty
//                               ? const Center(child: Text('No sites found'))
//                               : ListView.builder(
//                                   itemCount: sites.length,
//                                   itemBuilder: (context, index) {
//                                     final s = sites[index];
//                                     final name = s['name']?.toString() ?? '';
//                                     final location = s['location']?.toString() ?? '';
//                                     final status = s['status']?.toString() ?? '';
//                                     final progress = (s['progress'] != null) ? (s['progress'] as num).toInt() : 0;
//                                     final workers = s['worker_count'] ?? 0;
//                                     final isActive = s['is_active'] == true;

//                                     return Card(
//                                       margin: const EdgeInsets.symmetric(vertical: 8),
//                                       child: ListTile(
//                                         title: Text(name),
//                                         subtitle: Text('$location • ${status.toUpperCase()} • Progress: $progress% • Workers: $workers'),
//                                         trailing: Wrap(
//                                           spacing: 8,
//                                           children: [
//                                             IconButton(
//                                               icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off, color: AppColors.primary, size: 30),
//                                               onPressed: () => toggleIsActive(s),
//                                             ),
//                                             IconButton(
//                                               icon: const Icon(Icons.edit, color: Colors.orange),
//                                               onPressed: () => showSiteForm(site: s),
//                                             ),
//                                             IconButton(
//                                               icon: const Icon(Icons.delete, color: Colors.red),
//                                               onPressed: () {
//                                                 final id = s['id'];
//                                                 if (id is int) deleteSite(id);
//                                               },
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                         )
//                       ],
//                     ),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
