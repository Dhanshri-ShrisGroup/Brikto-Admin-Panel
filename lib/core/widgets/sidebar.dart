import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isCollapsed = true;


  @override
  Widget build(BuildContext context) {
  final mobile = isMobile(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: mobile
    ? AppSizes.sidebarExpandedWidth
    : (isCollapsed
        ? AppSizes.sidebarCollapsedWidth
        : AppSizes.sidebarExpandedWidth),
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 12),

          // 🔹 LOGO + TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                

                if (!mobile)
  IconButton(
    icon: Icon(
      isCollapsed ? Icons.menu_open : Icons.menu,
      color: AppColors.primary,
    ),
    onPressed: () {
      setState(() => isCollapsed = !isCollapsed);
    },
  ),

              ],
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 MENU ITEMS
          Expanded(
            child: ListView(
              
              children: [
                Image.asset(
                    'assets/Brikto_logo.jpeg',
                    height: 120,
                  ),
                SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  collapsed:  mobile ? false : isCollapsed,
                ),
                SidebarItem(
                  icon: Icons.person,
                  label: 'Developers',
                  route: '/developers',
                  collapsed:  mobile ? false : isCollapsed,
                ),
                SidebarItem(
                  icon: Icons.subscriptions,
                  label: 'Subscriptions',
                  route: '/subscriptions',
                  collapsed:  mobile ? false : isCollapsed,
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
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 900;
}
