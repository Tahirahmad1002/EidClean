import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'auth_widgets.dart';
import '../citizen/citizen_home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
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
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await context.read<AuthProvider>().signUp(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const CitizenHome()), (_) => false);
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthField(
          controller: ctrl,
          label: label,
          hint: hint,
          icon: icon,
          obscure: obscure,
          keyboard: keyboard,
          onToggleVisibility: onToggleVisibility,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildHero(double height) {
    return AuthHero(
      height: height,
      childBottom: 62,
      topSlot: Row(
        children: [
          _buildBackButton(),
          const Spacer(),
          const AuthLogoTile(
            icon: Icons.eco_rounded,
            size: 40,
            radius: 13,
            iconSize: 20,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Join EidClean today',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryLight.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final heroHeight = media.padding.top + 210;

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  _buildHero(heroHeight),
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - 46),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: AuthFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _field(
                                    ctrl: _nameCtrl,
                                    label: 'Full Name',
                                    hint: 'Ahmad Ali',
                                    icon: Icons.person_outline_rounded),
                                _field(
                                    ctrl: _emailCtrl,
                                    label: 'Email',
                                    hint: 'you@example.com',
                                    icon: Icons.mail_outline_rounded,
                                    keyboard: TextInputType.emailAddress),
                                _field(
                                    ctrl: _phoneCtrl,
                                    label: 'Phone Number',
                                    hint: '03001234567',
                                    icon: Icons.phone_outlined,
                                    keyboard: TextInputType.phone),
                                _field(
                                    ctrl: _passwordCtrl,
                                    label: 'Password',
                                    hint: 'minimum 6 characters',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: _obscure,
                                    onToggleVisibility: () {
                                      setState(() => _obscure = !_obscure);
                                    }),
                                if (_error != null)
                                  AuthErrorBox(message: _error!),
                                AuthPrimaryButton(
                                  label: 'Create Account',
                                  loading: _loading,
                                  onPressed: _loading ? null : _signup,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text.rich(
                  TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.bodyMuted,
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl + media.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
