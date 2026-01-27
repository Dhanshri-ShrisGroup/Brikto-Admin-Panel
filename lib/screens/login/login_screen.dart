import 'package:brikto_admin_panel/core/constants/colors.dart';
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
    // Save admin_id if needed
    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(row['message'] ?? 'Login failed')),
    );
  }
} else {
  // This should now rarely happen
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Invalid email or password')),
  );
}

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => loading = false);
  }
}


  void forgotPassword() {
    // Navigate to a Forgot Password page or show dialog
    Navigator.pushReplacementNamed(context, '/forgot-password');
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Brikto Logo
              Image.asset(
                'assets/brikto_logo.jpeg',
                height: 180,
              ),

              const SizedBox(height: 10),

              const Text(
                "Brikto Admin Panel",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Sign in to continue",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Email
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Password
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
  onPressed: loading ? null : login,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,// construction orange
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
                            
                  color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
