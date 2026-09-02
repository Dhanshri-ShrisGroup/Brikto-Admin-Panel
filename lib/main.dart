import 'package:brikto_admin_panel/app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brikto_admin_panel/app/app_router.dart';
import 'services/supabase_service.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();
  prefs = await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brikto Admin Panel',
      theme: appTheme,
      initialRoute: prefs.getBool('isLoggedIn') == true ? AppRouter.dashboard : AppRouter.login,
      routes: AppRouter.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
