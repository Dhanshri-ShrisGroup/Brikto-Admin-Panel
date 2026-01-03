import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const Navbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);
}
