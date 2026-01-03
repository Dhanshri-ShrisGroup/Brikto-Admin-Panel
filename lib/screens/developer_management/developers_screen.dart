




import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/sidebar.dart';
import 'dart:math';

class DeveloperManagementScreen extends StatefulWidget {
  const DeveloperManagementScreen({super.key});

  @override
  State<DeveloperManagementScreen> createState() => _DeveloperManagementScreenState();
}

class _DeveloperManagementScreenState extends State<DeveloperManagementScreen> {
  bool loading = true;
  List developers = [];

  final List<String> statusOptions = ['Active', 'Inactive', 'Expired', 'Suspended'];
  final List<String> planOptions = ['Monthly', 'Yearly', 'Custom'];

  @override
  void initState() {
    super.initState();
    fetchDevelopers();
  }

  Future<void> fetchDevelopers() async {
    setState(() => loading = true);
    try {
      final supabase = Supabase.instance.client;
      developers = await supabase.from('view_developers').select();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching developers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String generatePassword(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$%^&*';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void toggleDeveloperStatus(Map dev) async {
    try {
      final supabase = Supabase.instance.client;
      final newStatus = dev['status'] == 'Active' ? 'Inactive' : 'Active';
      await supabase.from('owner').update({'status': newStatus}).eq('id', dev['id']);
      fetchDevelopers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  void showDeveloperForm({Map? developer}) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: developer?['developer_name'] ?? '');
        final companyController = TextEditingController(text: developer?['company_name'] ?? '');
        final mobileController = TextEditingController(text: developer?['mobile'] ?? '');
        final emailController = TextEditingController(text: developer?['email'] ?? '');
        final passwordController = TextEditingController(
            text: developer == null ? generatePassword(10) : null);

        String selectedPlan = developer?['subscription_plan'] ?? 'Monthly';
        String selectedStatus = 'Active';

        DateTime? startDate = developer?['subscription_start_date'] != null
            ? DateTime.parse(developer!['subscription_start_date'])
            : null;
        DateTime? expiryDate = developer?['subscription_expiry_date'] != null
            ? DateTime.parse(developer!['subscription_expiry_date'])
            : null;

        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            title: Text(developer == null ? 'Add Developer' : 'Edit Developer'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Developer Name')),
                  TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company Name')),
                  TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Mobile')),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  if (developer == null)
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password (auto-generated)'),
                      readOnly: true,
                    ),
                  const SizedBox(height: 12),

                  // Subscription Plan Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedPlan,
                    items: planOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setStateSB(() => selectedPlan = val!),
                    decoration: const InputDecoration(labelText: 'Subscription Plan'),
                  ),

                  const SizedBox(height: 12),
                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: statusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setStateSB(() => selectedStatus = val!),
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),

                  const SizedBox(height: 12),
                  // Start Date Picker
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
  text: startDate != null ? "${startDate!.toLocal()}".split(' ')[0] : '',
),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setStateSB(() => startDate = picked);
                    },
                  ),

                  const SizedBox(height: 12),
                  // Expiry Date Picker
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                   controller: TextEditingController(
  text: expiryDate != null ? "${expiryDate!.toLocal()}".split(' ')[0] : '',
),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expiryDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setStateSB(() => expiryDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final supabase = Supabase.instance.client;

                    Map<String, dynamic> data = {
                      'full_name': nameController.text,
                      'company_name': companyController.text,
                      'phone': mobileController.text,
                      'email': emailController.text,
                      'subscription_plan': selectedPlan,
                      'subscription_start_date': startDate?.toIso8601String(),
                      'subscription_expiry_date': expiryDate?.toIso8601String(),
                      'status': selectedStatus,
                    };

                    if (developer == null) {
                      // // Insert new developer with hashed password
                      // final password = passwordController.text;
                      // data['password_hash'] = 'crypt($password, gen_salt(\'bf\'))';
                      // await supabase.from('owner').insert([data]);
                    } else {
                      await supabase.from('owner').update(data).eq('id', developer['id']);
                    }

                    Navigator.pop(context);
                    fetchDevelopers();
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error saving developer: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void viewSites(Map developer) {
    Navigator.pushNamed(context, '/sites', arguments: {'developerId': developer['id']});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const Navbar(title: 'Developer Management'),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: loading
                ? const LoadingIndicator()
                : Padding(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Developers',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: () => showDeveloperForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Developer'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        Expanded(
                          child: ListView.builder(
                            itemCount: developers.length,
                            itemBuilder: (context, index) {
                              final dev = developers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(dev['developer_name']),
                                  subtitle: Text(
                                      '${dev['company_name'] ?? ''} • ${dev['email']} • ${dev['status']}'),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      // IconButton(
                                      //   icon: Icon(
                                      //     dev['status'] == 'active'
                                      //         ? Icons.toggle_on
                                      //         : Icons.toggle_off,
                                      //     color: AppColors.primary,
                                      //     size: 30,
                                      //   ),
                                      //   onPressed: () => toggleDeveloperStatus(dev),
                                      // ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.orange),
                                        onPressed: () => showDeveloperForm(developer: dev),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.location_city, color: Colors.green),
                                        onPressed: () => viewSites(dev),
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
