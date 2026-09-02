import 'package:brikto_admin_panel/app/app_router.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../utils/responsive.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isCollapsed = false; // Always open by default now

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    
    // For large screens, we force it open (disable collapse). For mobile, it acts as a normal drawer so it is open when drawn.
    final effectiveCollapsed = mobile ? false : isCollapsed;
    final double width = mobile 
        ? AppSizes.sidebarExpandedWidth 
        : (effectiveCollapsed ? AppSizes.sidebarCollapsedWidth : AppSizes.sidebarExpandedWidth);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 12),

          if (!mobile) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: effectiveCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!effectiveCollapsed)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text(
                        "MENU",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  
                  // Hide toggle entirely on large screens if desired, but user just said "open for large screens". Let's keep toggle but it defaults to open. Or "Make the sidebar open for large screens" could imply fixed. Let's provide a toggle just in case they want more space, but default is open.
                  IconButton(
                    icon: Icon(
                      effectiveCollapsed ? Icons.menu : Icons.menu_open,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() => isCollapsed = !isCollapsed);
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // 🔹 MENU ITEMS
          Expanded(
            child: ListView(
              children: [
                // Logo removed as requested!
                SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: AppRouter.dashboard,
                  collapsed: effectiveCollapsed,
                ),
                SidebarItem(
                  icon: Icons.person,
                  label: 'Developers',
                  route: AppRouter.developers,
                  collapsed: effectiveCollapsed,
                ),
                // SidebarItem(
                //   icon: Icons.settings_suggest,
                //   label: 'Module Control',
                //   route: AppRouter.moduleControl,
                //   collapsed: effectiveCollapsed,
                // ),
                SidebarItem(
                  icon: Icons.subscriptions,
                  label: 'Subscriptions',
                  route: AppRouter.subscriptions,
                  collapsed: effectiveCollapsed,
                ),
                SidebarItem(
                  icon: Icons.workspace_premium,
                  label: 'PRO',
                  route: AppRouter.pro,
                  collapsed: effectiveCollapsed,
                ),
                SidebarItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Finance',
                  route: AppRouter.finance,
                  collapsed: effectiveCollapsed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool collapsed;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? label : '',
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: collapsed
            ? null
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
        // Changed pushReplacementNamed to pushNamed to retain navigation stack state so back browser button retains state!
        onTap: () {
          // If already on the route, do nothing. Otherwise, push it!
          final currentRoute = ModalRoute.of(context)?.settings.name;
          if (currentRoute != route) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
