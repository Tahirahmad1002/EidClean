import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../driver/driver_home.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  static const Color tealColor = Color(0xFF14897A);
  static const Color darkTeal = Color(0xFF0D6B5E);

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().signIn(
          email: _idController.text.trim(),
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

    if (auth.role == null && auth.user != null) {
      await auth.refreshUserRole();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    if (auth.isDriver) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHome()),
      );
    } else {
      setState(() {
        _error = 'This account is not registered as a driver.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ─── LOGO ──────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: tealColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: tealColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'EidClean',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DRIVER PORTAL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tealColor,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 32),

                // ─── HEADING ──────────────────
                const Text(
                  'Driver Login',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Login credentials provided by admin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 28),

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
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── EMPLOYEE ID ──────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Employee ID',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      hintText: 'Enter your ID',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.person_outline, color: tealColor, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── PASSWORD ──────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.lock_outline, color: tealColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ─── LOGIN BUTTON ──────────────
                Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [tealColor, darkTeal],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: tealColor.withOpacity(0.3),
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
                                'Login to Start',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── INFO BOX ──────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F5F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          color: tealColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your login credentials are provided by the EidClean administrator. Contact your supervisor if you need help.',
                          style: TextStyle(
                            color: tealColor,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}