import 'package:brikto_admin_panel/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
  '/dashboard': (context) => const DashboardScreen(),
},

      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
    
  }
  
}
