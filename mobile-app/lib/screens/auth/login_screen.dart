import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'citizen_login_screen.dart';
import 'driver_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isDriverTab = false;

  void _onRoleChanged(bool isDriver) {
    setState(() => _isDriverTab = isDriver);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _isDriverTab
            ? DriverLoginScreen(
                key: const ValueKey('driver'),
                onRoleChanged: _onRoleChanged,
              )
            : CitizenLoginScreen(
                key: const ValueKey('citizen'),
                onRoleChanged: _onRoleChanged,
              ),
      ),
    );
  }
}
