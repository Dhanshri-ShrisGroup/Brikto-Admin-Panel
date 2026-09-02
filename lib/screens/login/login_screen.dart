import 'package:brikto_admin_panel/core/constants/colors.dart';
import 'package:brikto_admin_panel/core/utils/dialogs.dart';
import 'package:brikto_admin_panel/core/utils/responsive.dart';
import 'package:brikto_admin_panel/main.dart';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      GlobalDialogs.showError(context, "Please enter both email and password.");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await SupabaseService.client.rpc(
        'admin_login',
        params: {
          'p_email': email.text.trim(),
          'p_password': password.text.trim(),
        },
      );

      if (res.isNotEmpty) {
        final row = res[0] as Map<String, dynamic>;
        if (row['success'] == true) {
          prefs.setBool('isLoggedIn', true);
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          GlobalDialogs.showError(context, row['message'] ?? 'Login failed');
        }
      } else {
        GlobalDialogs.showError(context, 'Invalid email or password');
      }
    } catch (e) {
      if (mounted) {
        GlobalDialogs.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: mobile ? double.infinity : 900,
          height: mobile ? double.infinity : 600,
          margin: mobile ? EdgeInsets.zero : const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: mobile ? BorderRadius.zero : BorderRadius.circular(24),
            boxShadow: mobile
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (!mobile)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Manage your construction projects with Brikto Admin Panel. Powerful, fast, and easy.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 48),
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              'assets/login_cartoon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (mobile) ...[
                            Center(
                              child: Image.asset(
                                'assets/Brikto_logo.jpeg',
                                height: 100,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Welcome Back!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Sign in to continue",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            Center(
                              child: Image.asset(
                                'assets/Brikto_logo.jpeg',
                                height: 80,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: password,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/forgot-password');
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
