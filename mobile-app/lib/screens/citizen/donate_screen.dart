// lib/screens/citizen/donate_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

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

  static final _Tone rose = _Tone(
    bg: const Color(0xFFFFF1F2),
    bg2: const Color(0xFFFFE4E6),
    border: const Color(0xFFFECDD3),
    from: const Color(0xFFFB7185),
    to: const Color(0xFFE11D48),
    fg: const Color(0xFFBE123C),
  );
}

// ─── DATA ────────────────────────────────────────────────────────────

class _Ngo {
  final String name;
  final String rating;
  final double distanceKm;
  final bool urgent;
  final bool verified;
  final int meatNeededKg;

  const _Ngo({
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.urgent,
    required this.verified,
    required this.meatNeededKg,
  });
}

const List<_Ngo> _ngos = [
  _Ngo(
    name: 'Edhi Foundation',
    rating: '4.9',
    distanceKm: 2.5,
    urgent: true,
    verified: true,
    meatNeededKg: 500,
  ),
  _Ngo(
    name: 'Saylani Welfare',
    rating: '4.8',
    distanceKm: 3.2,
    urgent: true,
    verified: true,
    meatNeededKg: 300,
  ),
];

class _FilterDef {
  final String label;
  final IconData icon;
  const _FilterDef(this.label, this.icon);
}

const List<_FilterDef> _filters = [
  _FilterDef('All', Icons.apps_rounded),
  _FilterDef('Verified', Icons.verified_rounded),
  _FilterDef('Near Me', Icons.near_me_rounded),
  _FilterDef('Urgent', Icons.local_fire_department_rounded),
];

// ─── SCREEN ──────────────────────────────────────────────────────────

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Ngo> get _filtered {
    final q = _query.trim().toLowerCase();
    return _ngos.where((n) {
      if (q.isNotEmpty && !n.name.toLowerCase().contains(q)) return false;
      switch (_filters[_filterIndex].label) {
        case 'Verified':
          return n.verified;
        case 'Near Me':
          return n.distanceKm <= 3;
        case 'Urgent':
          return n.urgent;
        default:
          return true;
      }
    }).toList();
  }

  void _donate(_Ngo ngo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Donation request noted for ${ngo.name}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

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
                        _Reveal(index: 0, child: _buildFilterRow()),
                        const SizedBox(height: 22),
                        _Reveal(index: 1, child: _buildImpactCard()),
                        const SizedBox(height: 26),
                        _Reveal(
                          index: 2,
                          child: _sectionTitle(
                            'Featured NGOs',
                            Icons.volunteer_activism_rounded,
                            _Tones.rose,
                            badge: '${items.length} found',
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (items.isEmpty)
                          _buildEmptyState()
                        else
                          for (int i = 0; i < items.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _Reveal(
                                index: i + 3,
                                child: _buildNgoCard(items[i]),
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
                _buildBackButton(),
                const SizedBox(height: 18),
                const AuthHeroChip(
                  icon: Icons.favorite_rounded,
                  label: 'GIVE THIS EID',
                ),
                const SizedBox(height: 12),
                Text(
                  'Donate to NGOs',
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
                    'Share your Qurbani meat with verified organizations',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeroStrip(),
                const SizedBox(height: 14),
                _buildSearchBar(),
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
    final urgent = _ngos.where((n) => n.urgent).length;
    final needed = _ngos.fold<int>(0, (sum, n) => sum + n.meatNeededKg);

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
          item(Icons.verified_rounded, 'NGOs', '${_ngos.length}'),
          divider(),
          item(Icons.local_fire_department_rounded, 'Urgent', '$urgent'),
          divider(),
          item(Icons.scale_rounded, 'Needed', '$needed kg'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 22,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: _Tones.amber200,
              style: AppTextStyles.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search NGOs...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── FILTERS ───────────────────────────────

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _filterChip(i),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(int i) {
    final f = _filters[i];
    final selected = _filterIndex == i;
    final tone = _Tones.emerald;

    return _PressScale(
      onTap: () => setState(() => _filterIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tone.from, tone.to],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? tone.to : tone.border),
          boxShadow: [
            BoxShadow(
              color: tone.to.withValues(alpha: selected ? 0.32 : 0.08),
              blurRadius: selected ? 14 : 8,
              offset: Offset(0, selected ? 6 : 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(f.icon, size: 16, color: selected ? Colors.white : tone.to),
            const SizedBox(width: 6),
            Text(
              f.label,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : tone.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── IMPACT CARD ───────────────────────────

  Widget _buildImpactCard() {
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
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AuthColors.emerald300.withValues(alpha: 0.28),
                        AppColors.secondary.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AuthColors.emerald200.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    size: 26,
                    color: AuthColors.emerald200,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Impact This Eid',
                        style: AppTextStyles.caption.copyWith(
                          color: AuthColors.emerald200.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 2500),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) {
                          return Text(
                            '${_withCommas(v)} kg',
                            style: AppTextStyles.h1.copyWith(
                              color: _Tones.amber200,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Meat donated to families in need',
                        style: AppTextStyles.caption.copyWith(
                          color: AuthColors.emerald200.withValues(alpha: 0.7),
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

  String _withCommas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // ─── NGO CARD ──────────────────────────────

  Widget _buildNgoCard(_Ngo ngo) {
    final tone = ngo.urgent ? _Tones.rose : _Tones.emerald;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _tintedCardDecoration(tone, 24),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -34,
            child: GlowCircle(
              size: 140,
              color: tone.from.withValues(alpha: 0.40),
            ),
          ),
          Positioned(
            right: -18,
            bottom: -24,
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 112,
              color: tone.to.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            top: 0,
            left: 18,
            right: 18,
            child: _topHighlight(tone),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _gradientTile(
                      Icons.volunteer_activism_rounded,
                      tone,
                      size: 52,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ngo.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ),
                              if (ngo.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primaryDark,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _infoPill(
                                Icons.star_rounded,
                                ngo.rating,
                                _Tones.amber,
                              ),
                              _infoPill(
                                Icons.location_on_rounded,
                                '${ngo.distanceKm.toStringAsFixed(1)} km',
                                _Tones.emerald,
                              ),
                              if (ngo.urgent)
                                _infoPill(
                                  Icons.local_fire_department_rounded,
                                  'Urgent',
                                  _Tones.rose,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: tone.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meat Needed',
                              style: AppTextStyles.caption.copyWith(
                                color: tone.fg.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${ngo.meatNeededKg} kg',
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: tone.fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _DonateButton(onTap: () => _donate(ngo)),
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

  Widget _infoPill(IconData icon, String text, _Tone tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tone.to),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: tone.fg,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final tone = _Tones.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _tintedCardDecoration(tone, 24),
      child: Row(
        children: [
          _gradientTile(Icons.search_off_rounded, tone, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No NGOs found',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try another filter or keyword.',
                  style: AppTextStyles.caption.copyWith(
                    color: tone.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _sectionTitle(String title, IconData icon, _Tone tone,
      {String? badge}) {
    return Row(
      children: [
        _gradientTile(icon, tone, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.bg2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.border),
            ),
            child: Text(
              badge,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: tone.fg,
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

/// Compact emerald gradient CTA used inside NGO cards.
class _DonateButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DonateButton({required this.onTap});

  @override
  State<_DonateButton> createState() => _DonateButtonState();
}

class _DonateButtonState extends State<_DonateButton> {
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
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AuthColors.emerald400
                    .withValues(alpha: _pressed ? 0.25 : 0.45),
                blurRadius: _pressed ? 8 : 16,
                offset: Offset(0, _pressed ? 2 : 7),
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
                height: 20,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Donate Now',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                  ),
                ],
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