import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Tailwind shades used on the web that are not part of AppColors.
class AuthColors {
  AuthColors._();
  static const Color emerald950 = Color(0xFF022C22);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color slate950 = Color(0xFF020617);
}

/// Light status-bar icons for screens that start with a dark hero.
class AuthSystemUi extends StatelessWidget {
  final Widget child;
  const AuthSystemUi({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: child,
    );
  }
}

/// Tiled eight-point-star (two overlapping squares) pattern.
class StarPatternPainter extends CustomPainter {
  final double alpha;
  final double tile;
  const StarPatternPainter({this.alpha = 0.06, this.tile = 44});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final dot = Paint()..color = Colors.white.withValues(alpha: alpha * 1.6);
    final r = tile * 0.27;

    for (double cy = 0; cy <= size.height + tile; cy += tile) {
      for (double cx = 0; cx <= size.width + tile; cx += tile) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          stroke,
        );
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
          stroke,
        );
        canvas.restore();
        canvas.drawCircle(Offset(cx + tile / 2, cy + tile / 2), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarPatternPainter old) =>
      old.alpha != alpha || old.tile != tile;
}

/// Soft radial glow used for ambient light.
class GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const GlowCircle({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

/// Full-bleed emerald hero with star pattern, amber glow and crescent.
/// [topSlot] is pinned under the status bar; [child] is anchored to the bottom.
class AuthHero extends StatelessWidget {
  final double height;
  final Widget child;
  final Widget? topSlot;
  final double childBottom;

  const AuthHero({
    super.key,
    required this.height,
    required this.child,
    this.topSlot,
    this.childBottom = 74,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuthColors.emerald900,
            AuthColors.emerald700,
            AppColors.secondaryDark,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald900.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: StarPatternPainter(alpha: 0.07, tile: 44),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: GlowCircle(
              size: 320,
              color: AuthColors.emerald400.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            top: -100,
            right: -70,
            child: GlowCircle(
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            top: top + 56,
            right: -22,
            child: Icon(
              Icons.nightlight_round,
              size: 150,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Positioned(
            top: top + 84,
            right: 84,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: AppColors.accent.withValues(alpha: 0.85),
            ),
          ),
          if (topSlot != null)
            Positioned(
              top: top + 10,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 428),
                  child: topSlot,
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: childBottom,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 428),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass segmented control with a sliding white pill.
class AuthRoleToggle extends StatelessWidget {
  final bool isRight;
  final ValueChanged<bool> onChanged;

  const AuthRoleToggle({
    super.key,
    required this.isRight,
    required this.onChanged,
  });

  Widget _tab({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color =
        active ? AuthColors.emerald900 : Colors.white.withValues(alpha: 0.8);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: const Duration(milliseconds: 220),
            builder: (context, c, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: c),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: c,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tab(
                label: 'Citizen',
                icon: Icons.person_outline,
                active: !isRight,
                onTap: () => onChanged(false),
              ),
              _tab(
                label: 'Driver',
                icon: Icons.local_shipping_outlined,
                active: isRight,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Glossy gradient logo tile with an amber dot or crescent badge.
class AuthLogoTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double radius;
  final double iconSize;
  final Color ringColor;
  final bool crescentBadge;

  const AuthLogoTile({
    super.key,
    required this.icon,
    this.size = 56,
    this.radius = 18,
    this.iconSize = 28,
    this.ringColor = AuthColors.emerald700,
    this.crescentBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = crescentBadge ? size * 0.34 : size * 0.2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AuthColors.emerald400, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size * 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: iconSize),
            ],
          ),
        ),
        Positioned(
          top: -badge * 0.35,
          right: -badge * 0.35,
          child: Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCD34D), AppColors.accent],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: crescentBadge
                ? Icon(
                    Icons.nightlight_round,
                    size: badge * 0.6,
                    color: AuthColors.emerald950,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Small glass pill used inside heroes.
class AuthHeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const AuthHeroChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFCD34D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 1.4,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Elevated white card (rounded 28) with a gradient accent strip.
class AuthFormCard extends StatelessWidget {
  final Widget child;
  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.07),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AuthColors.emerald900.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AuthColors.emerald400,
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Label + icon input (mirrors the React Input: slate border, emerald focus
/// border and soft ring).
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboard;
  final VoidCallback? onToggleVisibility;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.onToggleVisibility,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final hasToggle = widget.onToggleVisibility != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: focused ? AppColors.primaryDark : AppColors.slate700,
            ),
            child: Text(widget.label),
          ),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          padding: EdgeInsets.only(left: 14, right: hasToggle ? 4 : 14),
          decoration: BoxDecoration(
            color: focused ? AppColors.surface : AppColors.slate50,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: focused ? AppColors.primary : AppColors.slate200,
              width: 1.5,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      spreadRadius: 4,
                      blurRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  widget.icon,
                  key: ValueKey(focused),
                  size: 20,
                  color: focused ? AppColors.primary : AppColors.slate400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboard,
                  cursorColor: AppColors.primary,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.slate400,
                    ),
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (hasToggle)
                IconButton(
                  onPressed: widget.onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 40, height: 40),
                  splashRadius: 20,
                  icon: Icon(
                    widget.obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.slate400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Emerald gradient CTA with gloss, coloured shadow and press-scale.
class AuthPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: AppRadius.mdAll,
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withValues(alpha: _pressed ? 0.25 : 0.40),
                blurRadius: _pressed ? 10 : 22,
                offset: Offset(0, _pressed ? 3 : 10),
              ),
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 26,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.label,
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 140),
                            offset:
                                _pressed ? const Offset(0.15, 0) : Offset.zero,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White outlined button with press-scale.
class AuthSecondaryButton extends StatefulWidget {
  final String label;
  final Widget leading;
  final VoidCallback? onPressed;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.leading,
    required this.onPressed,
  });

  @override
  State<AuthSecondaryButton> createState() => _AuthSecondaryButtonState();
}

class _AuthSecondaryButtonState extends State<AuthSecondaryButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _pressed ? AppColors.slate50 : AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: _pressed ? AppColors.slate300 : AppColors.border,
              width: 1.5,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.leading,
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "OR" divider.
class AuthDivider extends StatelessWidget {
  final String label;
  const AuthDivider({super.key, this.label = 'OR'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.slate200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: AppTextStyles.overline),
        ),
        const Expanded(child: Divider(color: AppColors.slate200)),
      ],
    );
  }
}

/// Error banner that fades and slides in.
class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, v, child) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * -6),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.dangerLight.withValues(alpha: 0.55),
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.dangerDark,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.dangerDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
