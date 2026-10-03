import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import '../driver/driver_home.dart';

class DriverLoginScreen extends StatefulWidget {
  /// Called by the hero toggle (true = driver). Provided by LoginScreen.
  final ValueChanged<bool>? onRoleChanged;

  const DriverLoginScreen({super.key, this.onRoleChanged});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

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
    final media = MediaQuery.of(context);
    final heroHeight = media.padding.top + 306;

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  AuthHero(
                    height: heroHeight,
                    topSlot: widget.onRoleChanged == null
                        ? null
                        : AuthRoleToggle(
                            isRight: true,
                            onChanged: widget.onRoleChanged!,
                          ),
                    child: _buildHeroContent(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - 56),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _buildFormCard(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: _buildInfoBox(),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl + media.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AuthLogoTile(icon: Icons.local_shipping_outlined),
        const SizedBox(height: 12),
        const AuthHeroChip(
          icon: Icons.shield_outlined,
          label: 'DRIVER PORTAL',
        ),
        const SizedBox(height: 10),
        Text(
          'Driver Login',
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Login credentials provided by admin',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.primaryLight.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return AuthFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) AuthErrorBox(message: _error!),
          AuthField(
            controller: _idController,
            label: 'Employee ID',
            hint: 'Enter your ID',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            onToggleVisibility: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AuthPrimaryButton(
            label: 'Login to Start',
            loading: _loading,
            onPressed: _loading ? null : _login,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.55),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.accentDark,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your login credentials are provided by the EidClean administrator. Contact your supervisor if you need help.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
