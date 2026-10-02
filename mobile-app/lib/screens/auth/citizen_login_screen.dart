import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import '../citizen/citizen_home.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF0D3D14);

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    int attempts = 0;
    while (auth.loading && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CitizenHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                    _buildGoogleButton(),
                    const SizedBox(height: 30),
                    _buildSignupRow(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.eco_outlined, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Assalam-u-Alaikum 🤲',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Welcome back to EidClean',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryGreen, darkGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _loading ? null : _login,
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
              ),
              const SizedBox(width: 10),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: TextStyle(color: Colors.grey[700])),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SignupScreen(),
              ),
            );
          },
          child: const Text(
            'Create Account',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}