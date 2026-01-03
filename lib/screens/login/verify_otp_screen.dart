import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final otpController = TextEditingController();
  bool loading = false;
  late String email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    email = args?['email'] ?? '';
  }

  Future<void> verifyOtp() async {
    setState(() => loading = true);
    try {
      final res = await SupabaseService.client
          .from('admin_otp')
          .select()
          .eq('email', email)
          .eq('otp', otpController.text.trim())
          .gt('expires_at', DateTime.now().toIso8601String());

      if (res.isNotEmpty) {
        // OTP valid
        Navigator.pushNamed(context, '/reset-password', arguments: {'email': email});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error verifying OTP: $e')));
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
            TextField(controller: otpController, decoration: const InputDecoration(labelText: 'Enter OTP')),
            ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: loading ? const CircularProgressIndicator() : const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
