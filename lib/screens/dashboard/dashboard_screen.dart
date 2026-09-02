import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/sizes.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/loader.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/sidebar.dart';
import '../../core/utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;

  int totalDevelopers = 0;
  int totalSites = 0;
  int proActiveSites = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboardMetrics();
  }

  Future<void> fetchDashboardMetrics() async {
    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;

      final responses = await Future.wait([
        supabase.from('owner').select('id'),
        supabase.from('sites').select('id'),
        supabase.from('sites').select('id').eq('subscription_type', 'PRO'),
      ]);

      totalDevelopers = (responses[0] as List).length;
      totalSites = (responses[1] as List).length;
      proActiveSites = (responses[2] as List).length;
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
    final mobile = isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: mobile ? const Sidebar() : null,
      appBar: Navbar(title: 'Brikto Admin Panel',showMenu: mobile,),
      body: Row(
        children: [
          if (!mobile) const Sidebar(),
          // const Sidebar(),
          Expanded(
            child: loading
                ? const LoadingIndicator()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: AppSizes.defaultPadding,
      runSpacing: AppSizes.defaultPadding,
      children: [
        StatCard(title: 'Total Developers', value: '$totalDevelopers'),
        StatCard(title: 'Total Sites', value: '$totalSites'),
        StatCard(title: 'PRO Active Sites', value: '$proActiveSites'),
      ],
    ),
  ),
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
