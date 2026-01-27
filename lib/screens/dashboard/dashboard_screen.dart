import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/sidebar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;

  int totalDevelopers = 0;
  int activeDevelopers = 0;
  int expiredDevelopers = 0;
  int totalSites = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardMetrics();
  }

  Future<void> fetchDashboardMetrics() async {
    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;

      // Fetch all metrics from view
      final List metrics = await supabase.from(ApiConstants.dashboardMetrics).select();

      if (metrics.isNotEmpty) {
        final data = metrics.first;
        totalDevelopers = data['total_developers'] ?? 0;
        activeDevelopers = data['active_developers'] ?? 0;
        expiredDevelopers = data['expired_developers'] ?? 0;
        totalSites = data['total_sites'] ?? 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching dashboard: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const Navbar(title: 'Brikto Admin Panel'),
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: loading
                ? const LoadingIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.defaultPadding),

                        // Metrics Cards
                        Wrap(
                          spacing: AppSizes.defaultPadding,
                          runSpacing: AppSizes.defaultPadding,
                          children: [
                            StatCard(title: 'Total Developers', value: '$totalDevelopers'),
                            StatCard(title: 'Active Developers', value: '$activeDevelopers'),
                            StatCard(title: 'Expired Developers', value: '$expiredDevelopers'),
                            StatCard(title: 'Total Sites', value: '$totalSites'),
                          ],
                        ),

                        const SizedBox(height: AppSizes.defaultPadding * 2),

                        // Recent Activity Table Placeholder
                        // const Text(
                        //   'Recent Actions',
                        //   style: TextStyle(
                        //       fontSize: 20,
                        //       fontWeight: FontWeight.bold,
                        //       color: AppColors.textPrimary),
                        // ),
                        const SizedBox(height: AppSizes.defaultPadding),
                        // RecentActivityTable(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------- RecentActivityTable ----------------
class RecentActivityTable extends StatelessWidget {
  const RecentActivityTable({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data, can be replaced with API call
    final activities = [
      {'action': 'Developer Added', 'time': '1 hour ago'},
      {'action': 'Site Created', 'time': '2 hours ago'},
      {'action': 'Developer Activated', 'time': '5 hours ago'},
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Time')),
        ],
        rows: activities
            .map(
              (a) => DataRow(cells: [
                DataCell(Text(a['action']!)),
                DataCell(Text(a['time']!)),
              ]),
            )
            .toList(),
      ),
    );
  }
}
