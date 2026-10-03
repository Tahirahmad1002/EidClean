import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'auth/auth_widgets.dart';
import 'auth/login_screen.dart';
import 'citizen/citizen_home.dart';
import 'driver/driver_home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _Spark {
  final Alignment alignment;
  final double size;
  final double phase;
  const _Spark(this.alignment, this.size, this.phase);
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulse;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  static const List<_Spark> _sparks = [
    _Spark(Alignment(-0.78, -0.62), 4, 0.0),
    _Spark(Alignment(0.72, -0.48), 3, 0.35),
    _Spark(Alignment(-0.55, 0.34), 3, 0.6),
    _Spark(Alignment(0.82, 0.18), 4, 0.15),
    _Spark(Alignment(-0.9, -0.12), 3, 0.8),
    _Spark(Alignment(0.45, -0.78), 3, 0.5),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulse = AnimationController(
      duration: const Duration(milliseconds: 3600),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AuthColors.emerald950,
        body: Stack(
          children: [
            // Deep emerald gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AuthColors.emerald950,
                      AuthColors.emerald900,
                      AuthColors.slate950,
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Star pattern
            const Positioned.fill(
              child: CustomPaint(
                painter: StarPatternPainter(alpha: 0.05, tile: 48),
              ),
            ),

            // Vignette to focus the centre
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        AuthColors.emerald950.withValues(alpha: 0.75),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Ambient glows
            Positioned(
              top: -150,
              left: -130,
              child: GlowCircle(
                size: 400,
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            Positioned(
              bottom: -170,
              right: -130,
              child: GlowCircle(
                size: 400,
                color: AppColors.accent.withValues(alpha: 0.16),
              ),
            ),

            // Crescent, bottom-right
            Positioned(
              bottom: 40,
              right: -34,
              child: Icon(
                Icons.nightlight_round,
                size: 220,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: 196,
              right: 74,
              child: Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.accent.withValues(alpha: 0.7),
              ),
            ),

            // Twinkling sparks
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Stack(
                    children: [
                      for (final s in _sparks)
                        Align(
                          alignment: s.alignment,
                          child: Opacity(
                            opacity: 0.15 +
                                0.65 *
                                    math
                                        .sin((_pulse.value + s.phase) * math.pi)
                                        .abs(),
                            child: Container(
                              width: s.size,
                              height: s.size,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Brand
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SizedBox(
                          width: 104,
                          height: 104,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              OverflowBox(
                                maxWidth: 340,
                                maxHeight: 340,
                                child: AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, _) => Opacity(
                                    opacity: 0.65 + 0.35 * _pulse.value,
                                    child: GlowCircle(
                                      size: 340,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.38),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RingsPainter(_pulse),
                                ),
                              ),
                              const AuthLogoTile(
                                icon: Icons.eco_rounded,
                                size: 104,
                                radius: 30,
                                iconSize: 52,
                                ringColor: AuthColors.emerald900,
                                crescentBadge: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (rect) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, AuthColors.emerald200],
                              ).createShader(rect),
                              child: Text(
                                'EidClean',
                                style: AppTextStyles.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Eid ul Adha Waste Management',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: AuthColors.emerald200
                                    .withValues(alpha: 0.6),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const AuthHeroChip(
                              icon: Icons.location_on_outlined,
                              label: 'ABBOTTABAD',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Progress + version
            Positioned(
              left: 56,
              right: 56,
              bottom: 56 + bottomInset,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 3),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 4,
                            width: double.infinity,
                            color: Colors.white.withValues(alpha: 0.10),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: value,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AuthColors.emerald400,
                                      AppColors.accent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading',
                      style: AppTextStyles.caption.copyWith(
                        color: AuthColors.emerald200.withValues(alpha: 0.6),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20 + bottomInset,
              child: Text(
                'v1.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AuthColors.emerald200.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three breathing rings around the logo.
class _RingsPainter extends CustomPainter {
  final Animation<double> t;
  _RingsPainter(this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (int i = 0; i < 3; i++) {
      final r = 78.0 + i * 40.0 + t.value * 8.0 * (i + 1);
      final a = (0.18 - i * 0.05) * (0.6 + 0.4 * t.value);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AuthColors.emerald400.withValues(alpha: a);
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => false;
}
