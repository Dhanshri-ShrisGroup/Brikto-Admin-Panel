import 'package:brikto_admin_panel/screens/dashboard/dashboard_screen.dart';
import 'package:brikto_admin_panel/screens/developer_management/developers_screen.dart';
import 'package:brikto_admin_panel/screens/login/forgot_password_screen.dart';
import 'package:brikto_admin_panel/screens/login/login_screen.dart';
import 'package:brikto_admin_panel/screens/login/reset_password_screen.dart';
import 'package:brikto_admin_panel/screens/login/verify_otp_screen.dart';
import 'package:brikto_admin_panel/screens/module_control/module_control_screen.dart';
import 'package:brikto_admin_panel/screens/pro_management/pro_management_screen.dart';
import 'package:brikto_admin_panel/screens/site_management/site_screen.dart';
import 'package:brikto_admin_panel/screens/subscription/subscription_management_v2_screen.dart';
import 'package:brikto_admin_panel/screens/finance/finance_screen.dart';
import 'package:flutter/material.dart';
import 'package:brikto_admin_panel/main.dart'; // To access prefs

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String developers = '/developers';
  static const String sites = '/sites';
  static const String requests = '/requests';
  static const String subscriptions = '/subscriptions';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String moduleControl = '/module-control';
  static const String pro = '/pro';
  static const String finance = '/finance';

  static Widget _protect(Widget screen) {
    if (prefs.getBool('isLoggedIn') != true) {
      return const LoginScreen();
    }
    return screen;
  }
  
  static Widget _auth(Widget screen) {
    if (prefs.getBool('isLoggedIn') == true) {
      return const DashboardScreen();
    }
    return screen;
  }

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => _auth(const LoginScreen()),
        dashboard: (context) => _protect(const DashboardScreen()),
        developers: (context) => _protect(const DeveloperManagementScreen()),
        sites: (context) => _protect(const SitesScreen()),
        subscriptions: (context) => _protect(const SubscriptionManagementPage()),
        forgotPassword: (context) => _auth(const ForgotPasswordScreen()),
        verifyOtp: (context) => _auth(const VerifyOtpScreen()),
        resetPassword: (context) => _auth(const ResetPasswordScreen()),
        moduleControl: (context) => _protect(const ModuleControlPage()),
        pro: (context) => _protect(const ProManagementScreen()),
        finance: (context) => _protect(const FinanceScreen()),
      };
}
