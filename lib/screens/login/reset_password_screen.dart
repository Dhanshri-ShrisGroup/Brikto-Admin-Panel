import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool loading = false;
  late String email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    email = args?['email'] ?? '';
  }

  Future<void> resetPassword() async {
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => loading = true);
    try {
      await SupabaseService.client.from('super_admins').update({
        'password_hash': 'crypt(${passwordController.text}, gen_salt(\'bf\'))',
      }).eq('email', email);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful')));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error resetting password: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
            TextField(controller: confirmController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            ElevatedButton(
              onPressed: loading ? null : resetPassword,
              child: loading ? const CircularProgressIndicator() : const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
