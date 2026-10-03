import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import 'signup_screen.dart';
import '../citizen/citizen_home.dart';

class CitizenLoginScreen extends StatefulWidget {
  /// Called by the hero toggle (true = driver). Provided by LoginScreen.
  final ValueChanged<bool>? onRoleChanged;

  const CitizenLoginScreen({super.key, this.onRoleChanged});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final _emailController = TextEditingController();
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
    final media = MediaQuery.of(context);
    final heroHeight = media.padding.top + 282;

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
                            isRight: false,
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
              _buildSignupRow(),
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
        const AuthLogoTile(icon: Icons.eco_rounded),
        const SizedBox(height: 14),
        Text(
          'Assalam-u-Alaikum',
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
          'Welcome back to EidClean',
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
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
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
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AuthPrimaryButton(
            label: 'Login',
            loading: _loading,
            onPressed: _loading ? null : _login,
          ),
          const SizedBox(height: 20),
          const AuthDivider(),
          const SizedBox(height: 20),
          AuthSecondaryButton(
            label: 'Continue with Google',
            leading: const Icon(
              Icons.g_mobiledata,
              size: 30,
              color: AppColors.slate700,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSignupRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: AppTextStyles.bodyMuted),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SignupScreen(),
              ),
            );
          },
          child: Text(
            'Sign Up',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
