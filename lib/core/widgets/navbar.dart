import 'package:brikto_admin_panel/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:brikto_admin_panel/main.dart'; // import prefs
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../utils/responsive.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenu;

  const Navbar({
    super.key,
    required this.title,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 1,

      // ✅ Mobile menu button
      leading: showMenu
          ? Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,

      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 18 : 22,
        ),
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            prefs.setBool('isLoggedIn', false);
            Navigator.pushReplacementNamed(context, AppRouter.login);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);
}
