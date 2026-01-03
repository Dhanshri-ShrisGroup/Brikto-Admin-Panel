import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/sidebar.dart';
import '../../core/widgets/navbar.dart';

final supabase = Supabase.instance.client;

const List<String> modules = [
  'customer',
  'material',
  'stock',
  'vendor',
  'expenses',
  'daily_work',
  'staff',
  'reports',
  'notifications'
];

class ModuleControlPage extends StatefulWidget {
  const ModuleControlPage({super.key});
  static const routeName = '/module-control';

  @override
  State<ModuleControlPage> createState() => _ModuleControlPageState();
}

class _ModuleControlPageState extends State<ModuleControlPage> {
  List<Map<String, dynamic>> developers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDevelopers();
  }

  Future<void> loadDevelopers() async {
    setState(() => loading = true);
    try {
      final data = await supabase
          .from('developer_module_view')
          .select()
          .order('developer_name', ascending: true) as List<dynamic>;

      developers = data.map((dev) => Map<String, dynamic>.from(dev)).toList();
    } catch (e) {
      debugPrint('Error fetching developers: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to fetch developers')));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> toggleModule(int developerId, String moduleName, bool currentValue) async {
    try {
      await supabase.rpc('toggle_module_for_developer', params: {
        'p_developer_id': developerId,
        'p_module_name': moduleName,
        'p_enabled': !currentValue,
      });

      setState(() {
        developers = developers.map((dev) {
          if (dev['developer_id'] == developerId) {
            dev[moduleName] = !currentValue;
          }
          return dev;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error toggling module: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to toggle module')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const Navbar(title: 'Module Control'),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: developers.map((dev) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dev['developer_name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 16,
                                        children: modules.map((mod) {
                                          bool enabled = dev[mod] ?? true;
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  enabled ? Icons.check_circle : Icons.cancel,
                                                  color: enabled ? Colors.green : Colors.red,
                                                  size: 28,
                                                ),
                                                onPressed: () => toggleModule(
                                                    dev['developer_id'], mod, enabled),
                                              ),
                                              Text(
                                                mod.replaceAll('_', ' ').toUpperCase(),
                                                style:
                                                    const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
