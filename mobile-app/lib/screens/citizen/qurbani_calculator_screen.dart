// lib/screens/citizen/qurbani_calculator_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

// ─── DOMAIN LOGIC (unchanged) ────────────────────────────────────────

class QurbaniDistribution {
  final double totalWeightKg;
  final double householdShareKg;
  final double relativesShareKg;
  final double needyShareKg;
  final String guidance;

  const QurbaniDistribution({
    required this.totalWeightKg,
    required this.householdShareKg,
    required this.relativesShareKg,
    required this.needyShareKg,
    required this.guidance,
  });
}

QurbaniDistribution calculateQurbaniDistribution({required double weightKg}) {
  if (weightKg <= 0) {
    return const QurbaniDistribution(
      totalWeightKg: 0,
      householdShareKg: 0,
      relativesShareKg: 0,
      needyShareKg: 0,
      guidance: 'Please enter a valid animal weight to calculate the shares.',
    );
  }

  final share = weightKg / 3;
  return QurbaniDistribution(
    totalWeightKg: weightKg,
    householdShareKg: share,
    relativesShareKg: share,
    needyShareKg: share,
    guidance:
        'A common Islamic guidance is to divide the meat into three equal shares: one-third for your household, one-third for relatives/friends, and one-third for the needy.',
  );
}

QurbaniDistribution calculateQurbaniRecommendation({
  required int adults,
  required int children,
  required String animalType,
}) {
  final weightKg = adults * 20 + children * 10;
  return calculateQurbaniDistribution(weightKg: weightKg.toDouble());
}

// ─── TINTS ───────────────────────────────────────────────────────────

class _Tone {
  final Color bg;
  final Color bg2;
  final Color border;
  final Color from;
  final Color to;
  final Color fg;
  const _Tone({
    required this.bg,
    required this.bg2,
    required this.border,
    required this.from,
    required this.to,
    required this.fg,
  });
}

class _Tones {
  _Tones._();

  static const Color teal700 = Color(0xFF0F766E);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber200 = Color(0xFFFDE68A);

  static final _Tone emerald = _Tone(
    bg: AppColors.primaryBg,
    bg2: AppColors.primaryLight,
    border: AuthColors.emerald200,
    from: AuthColors.emerald400,
    to: AppColors.primaryDark,
    fg: AuthColors.emerald700,
  );

  static final _Tone amber = _Tone(
    bg: const Color(0xFFFFFBEB),
    bg2: const Color(0xFFFEF3C7),
    border: const Color(0xFFFDE68A),
    from: const Color(0xFFFCD34D),
    to: AppColors.accentDark,
    fg: const Color(0xFFB45309),
  );

  static final _Tone blue = _Tone(
    bg: const Color(0xFFEFF6FF),
    bg2: const Color(0xFFDBEAFE),
    border: const Color(0xFFBFDBFE),
    from: const Color(0xFF60A5FA),
    to: const Color(0xFF2563EB),
    fg: const Color(0xFF1D4ED8),
  );

  static final _Tone rose = _Tone(
    bg: const Color(0xFFFFF1F2),
    bg2: const Color(0xFFFFE4E6),
    border: const Color(0xFFFECDD3),
    from: const Color(0xFFFB7185),
    to: const Color(0xFFE11D48),
    fg: const Color(0xFFBE123C),
  );
}

// ─── SCREEN ──────────────────────────────────────────────────────────

class QurbaniCalculatorScreen extends StatefulWidget {
  const QurbaniCalculatorScreen({super.key});

  @override
  State<QurbaniCalculatorScreen> createState() =>
      _QurbaniCalculatorScreenState();
}

class _QurbaniCalculatorScreenState extends State<QurbaniCalculatorScreen> {
  final _weightController = TextEditingController(text: '30');
  QurbaniDistribution? _result;
  int _calcCount = 0;

  static const List<int> _presets = [20, 30, 60, 120];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    setState(() {
      _result = calculateQurbaniDistribution(weightKg: weight);
      _calcCount++;
    });
  }

  void _setPreset(int kg) {
    setState(() {
      _weightController.text = '$kg';
      _weightController.selection = TextSelection.collapsed(
        offset: _weightController.text.length,
      );
    });
  }

  bool get _hasValidResult => _result != null && _result!.totalWeightKg > 0;

  @override
  Widget build(BuildContext context) {
    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Reveal(index: 0, child: _buildInfoCard()),
                        const SizedBox(height: 26),
                        _Reveal(
                          index: 1,
                          child: _sectionTitle(
                            'Animal Weight',
                            Icons.scale_rounded,
                            _Tones.emerald,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _Reveal(index: 2, child: _buildWeightCard()),
                        const SizedBox(height: 18),
                        _Reveal(
                          index: 3,
                          child: _GradientCta(
                            label: 'Calculate Shares',
                            icon: Icons.calculate_rounded,
                            onPressed: _calculate,
                          ),
                        ),
                        if (_result != null) ...[
                          const SizedBox(height: 28),
                          KeyedSubtree(
                            key: ValueKey(_calcCount),
                            child: _buildResults(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BACKDROP ──────────────────────────────

  Widget _buildBackdrop() {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBg,
                  AppColors.slate50,
                  Color(0xFFEFF6F3),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: GlowCircle(
            size: 380,
            color: AuthColors.emerald400.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          bottom: 200,
          left: -150,
          child: GlowCircle(
            size: 320,
            color: AppColors.accent.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─── HERO ──────────────────────────────────

  Widget _buildHero() {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuthColors.emerald900,
            AuthColors.emerald700,
            _Tones.teal700,
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        border: Border.all(color: AuthColors.emerald950.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald950.withValues(alpha: 0.38),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _MaskedLattice()),
          Positioned(
            top: -90,
            right: -60,
            child: GlowCircle(
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            bottom: -110,
            left: 40,
            child: GlowCircle(
              size: 280,
              color: const Color(0xFF5EEAD4).withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: top + 50,
            right: -34,
            child: Icon(
              Icons.nightlight_round,
              size: 190,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: top + 14,
            right: 28,
            child: Transform.rotate(
              angle: 0.32,
              child: Icon(
                Icons.nightlight_round,
                size: 50,
                color: _Tones.amber200.withValues(alpha: 0.92),
                shadows: [
                  Shadow(
                    color: _Tones.amber300.withValues(alpha: 0.65),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 70,
            right: 96,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: _Tones.amber300.withValues(alpha: 0.9),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canPop) ...[
                  _buildBackButton(),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 8),
                const AuthHeroChip(
                  icon: Icons.calculate_rounded,
                  label: 'MEAT CALCULATOR',
                ),
                const SizedBox(height: 12),
                Text(
                  'Qurbani Meat Guide',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 56),
                  child: Text(
                    'Divide your Qurbani meat into three equal shares',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeroStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  Widget _buildHeroStrip() {
    final r = _result;
    final ok = _hasValidResult;

    Widget item(IconData icon, String label, String value) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: AuthColors.emerald200.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AuthColors.emerald200.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget divider() => Container(
        width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15));

    return Container(
      decoration: BoxDecoration(
        color: AuthColors.emerald950.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          item(
            Icons.scale_rounded,
            'Total',
            ok ? '${r!.totalWeightKg.toStringAsFixed(1)} kg' : '—',
          ),
          divider(),
          item(
            Icons.pie_chart_rounded,
            'Per share',
            ok ? '${r!.householdShareKg.toStringAsFixed(1)} kg' : '—',
          ),
          divider(),
          item(Icons.groups_rounded, 'Shares', '3'),
        ],
      ),
    );
  }

  // ─── INFO + INPUT ──────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBg, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthColors.emerald200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _gradientTile(Icons.favorite_rounded, _Tones.emerald, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estimate how the meat can be divided into three equal shares for household, relatives, and the needy.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AuthColors.emerald900,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _tintedCardDecoration(_Tones.emerald, 24),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: GlowCircle(
              size: 150,
              color: _Tones.emerald.from.withValues(alpha: 0.35),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                cursorColor: AppColors.primary,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
                decoration: InputDecoration(
                  hintText: 'Example: 60',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.slate400,
                  ),
                  prefixIcon: const Icon(
                    Icons.scale_rounded,
                    color: AppColors.primaryDark,
                  ),
                  suffixText: 'kg',
                  suffixStyle: AppTextStyles.titleMedium.copyWith(
                    color: AuthColors.emerald700,
                    fontWeight: FontWeight.w800,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: _Tones.emerald.border,
                      width: 1.3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: _Tones.emerald.border,
                      width: 1.3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.8,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Quick pick',
                style: AppTextStyles.labelSmall.copyWith(
                  color: _Tones.emerald.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _presets) _presetChip(p),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int kg) {
    final selected = _weightController.text.trim() == '$kg';
    return _PressScale(
      onTap: () => _setPreset(kg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [_Tones.emerald.from, _Tones.emerald.to],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _Tones.emerald.to : _Tones.emerald.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _Tones.emerald.to.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$kg kg',
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : _Tones.emerald.fg,
          ),
        ),
      ),
    );
  }

  // ─── RESULTS ───────────────────────────────

  Widget _buildResults() {
    final r = _result!;

    if (r.totalWeightKg <= 0) {
      return _Reveal(index: 0, child: _buildWarningCard(r.guidance));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Reveal(
          index: 0,
          child: _sectionTitle(
            'Meat Distribution',
            Icons.pie_chart_rounded,
            _Tones.amber,
          ),
        ),
        const SizedBox(height: 12),
        _Reveal(index: 1, child: _buildTotalCard(r)),
        const SizedBox(height: 14),
        _Reveal(
          index: 2,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _shareCard(
                    'Household',
                    Icons.home_rounded,
                    _Tones.emerald,
                    r.householdShareKg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shareCard(
                    'Relatives',
                    Icons.diversity_3_rounded,
                    _Tones.blue,
                    r.relativesShareKg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shareCard(
                    'Needy',
                    Icons.volunteer_activism_rounded,
                    _Tones.rose,
                    r.needyShareKg,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _Reveal(index: 3, child: _buildCharityCard()),
      ],
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _tintedCardDecoration(_Tones.amber, 20),
      child: Row(
        children: [
          _gradientTile(Icons.warning_amber_rounded, _Tones.amber, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: _Tones.amber.fg,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(QurbaniDistribution r) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuthColors.emerald900,
            AuthColors.emerald950,
            AuthColors.slate950,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AuthColors.emerald700.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald950.withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: StarPatternPainter(alpha: 0.05, tile: 40),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: GlowCircle(
              size: 260,
              color: AuthColors.emerald400.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: GlowCircle(
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AuthColors.emerald300.withValues(alpha: 0.28),
                            AppColors.secondary.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AuthColors.emerald200.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.scale_rounded,
                        size: 21,
                        color: AuthColors.emerald200,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total meat weight',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Split equally three ways',
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  AuthColors.emerald200.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: r.totalWeightKg),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) {
                        return Text(
                          '${v.toStringAsFixed(1)} kg',
                          style: AppTextStyles.h2.copyWith(
                            color: _Tones.amber200,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 9,
                    child: Row(
                      children: [
                        Expanded(
                          child: ColoredBox(color: _Tones.emerald.from),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: ColoredBox(color: _Tones.blue.from),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: ColoredBox(color: _Tones.rose.from),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 16,
                        color: _Tones.amber300,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.guidance,
                          style: AppTextStyles.caption.copyWith(
                            color: AuthColors.emerald200.withValues(alpha: 0.9),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shareCard(String label, IconData icon, _Tone tone, double kg) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: _tintedCardDecoration(tone, 22),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -44,
            child: GlowCircle(
              size: 100,
              color: tone.from.withValues(alpha: 0.40),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _gradientTile(icon, tone, size: 36),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: kg),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      v.toStringAsFixed(1),
                      style: AppTextStyles.stat.copyWith(
                        fontSize: 26,
                        color: tone.fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
              Text(
                'kg',
                style: AppTextStyles.caption.copyWith(
                  color: tone.fg.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharityCard() {
    final tone = _Tones.rose;
    return _PressScale(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'NGO donation coordination will be added in the next module step.',
            ),
          ),
        );
      },
      child: Container(
        height: 84,
        clipBehavior: Clip.antiAlias,
        decoration: _tintedCardDecoration(tone, 24),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: GlowCircle(
                size: 150,
                color: tone.from.withValues(alpha: 0.40),
              ),
            ),
            Positioned(
              top: 0,
              left: 18,
              right: 18,
              child: _topHighlight(tone),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _gradientTile(Icons.handshake_rounded, tone, size: 50),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request charity support',
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share the needy portion with an NGO',
                            style: AppTextStyles.caption.copyWith(
                              color: tone.fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tone.bg2,
                        shape: BoxShape.circle,
                        border: Border.all(color: tone.border),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: tone.to,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED PIECES ─────────────────────────

  BoxDecoration _tintedCardDecoration(_Tone tone, double radius) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [tone.bg, tone.bg2],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: tone.border, width: 1.3),
      boxShadow: [
        BoxShadow(
          color: tone.to.withValues(alpha: 0.16),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _topHighlight(_Tone tone) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            tone.to.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _gradientTile(IconData icon, _Tone tone, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.from, tone.to],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(icon, color: Colors.white, size: size * 0.52),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, _Tone tone) {
    return Row(
      children: [
        _gradientTile(icon, tone, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── REUSABLE VISUAL PIECES ──────────────────────────────────────────

class _MaskedLattice extends StatelessWidget {
  final double alpha;
  const _MaskedLattice({this.alpha = 0.13});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.black, Colors.transparent],
          stops: [0.0, 0.9],
        ).createShader(rect),
        child: CustomPaint(
          painter: StarPatternPainter(alpha: alpha, tile: 44),
        ),
      ),
    );
  }
}

class _GradientCta extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _GradientCta({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_GradientCta> createState() => _GradientCtaState();
}

class _GradientCtaState extends State<_GradientCta> {
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
          height: 56,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.primaryDark],
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AuthColors.emerald400
                    .withValues(alpha: _pressed ? 0.28 : 0.52),
                blurRadius: _pressed ? 10 : 24,
                offset: Offset(0, _pressed ? 3 : 12),
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
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 16,
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

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
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
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  final int index;
  final Widget child;
  const _Reveal({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 110),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
