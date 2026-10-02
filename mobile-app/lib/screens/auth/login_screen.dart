import 'package:flutter/material.dart';
import 'citizen_login_screen.dart';
import 'driver_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isDriverTab = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 40),

          // ─── TOGGLE ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDriverTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDriverTab
                              ? Colors.transparent
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Citizen',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isDriverTab
                                ? const Color(0xFF6B7280)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDriverTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDriverTab
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Driver',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isDriverTab
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── CONTENT ─────────────────────
          Expanded(
            child: _isDriverTab
                ? const DriverLoginScreen()
                : const CitizenLoginScreen(),
          ),
        ],
      ),
    );
  }
}