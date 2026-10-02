import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../citizen/citizen_home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _signup() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final error = await context.read<AuthProvider>().signUp(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      phone:    _phoneCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      setState(() { _error = error; _loading = false; });
      return;
    }

    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const CitizenHome()),
      (_) => false);
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF10B981), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF111827)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Join EidClean today',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              _field(ctrl: _nameCtrl,
                label: 'Full Name',
                hint: 'Ahmad Ali',
                icon: Icons.person_outline),

              _field(ctrl: _emailCtrl,
                label: 'Email',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress),

              _field(ctrl: _phoneCtrl,
                label: 'Phone Number',
                hint: '03001234567',
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone),

              _field(ctrl: _passwordCtrl,
                label: 'Password',
                hint: 'minimum 6 characters',
                icon: Icons.lock_outline,
                obscure: _obscure),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 13)),
                ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Color(0xFF6B7280)),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600),
                        ),
                      ],
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