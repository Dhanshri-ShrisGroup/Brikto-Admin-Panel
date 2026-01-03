import 'package:brikto_admin_panel/screens/Requests/DeveloperRequest.dart';
import 'package:brikto_admin_panel/screens/login/login_screen.dart';
import 'package:brikto_admin_panel/screens/module_control/module_control_screen.dart';
import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/developer_management/developers_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/login/reset_password_screen.dart';
import 'screens/login/verify_otp_screen.dart';
import 'screens/site_management/site_screen.dart';
import 'screens/subscription/subscription_management_scrren.dart';
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
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/developers': (context) => const DeveloperManagementScreen(),
        // '/sites': (context) => const SitesScreen(),
        '/requests': (context) =>  OwnerRequestsPage(),

        '/subscriptions': (context) => SubscriptionManagementPage(),
'/forgot-password': (context) => const ForgotPasswordScreen(),
  '/verify-otp': (context) => const VerifyOtpScreen(),
  '/reset-password': (context) => const ResetPasswordScreen(),
  '/module-control': (context) => const ModuleControlPage(),
  
//         '/settings': (context) => const SettingsScreen(),
},

      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
    
  }
  
}
