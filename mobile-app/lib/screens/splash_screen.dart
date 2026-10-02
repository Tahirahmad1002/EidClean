import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'citizen/citizen_home.dart';
import 'driver/driver_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    if (auth.user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else if (auth.isDriver) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CitizenHome()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10B981),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'EidClean',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Eid-ul-Adha Waste Management',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}