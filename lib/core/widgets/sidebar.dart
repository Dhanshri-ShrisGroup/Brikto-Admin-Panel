import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sidebarWidth,
      color: AppColors.cardBackground,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.defaultPadding),
        children: [
          const FlutterLogo(size: 80),
          const SizedBox(height: AppSizes.defaultPadding),
          SidebarItem(icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
          SidebarItem(icon: Icons.person, label: 'Developers', route: '/developers'),
          SidebarItem(icon: Icons.location_city, label: 'Developer Request', route: '/requests'),
          // SidebarItem(icon: Icons.settings_applications, label: 'Module Control', route: '/module-control'),
          SidebarItem(icon: Icons.subscriptions, label: 'Subscription ', route: '/subscriptions'),
          SidebarItem(icon: Icons.settings, label: 'Settings', route: '/settings'),
        ],
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}
