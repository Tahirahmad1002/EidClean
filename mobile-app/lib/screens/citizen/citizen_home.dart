// lib/screens/citizen/citizen_home.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'book_pickup_screen.dart';
import 'my_requests_screen.dart';
import 'qurbani_calculator_screen.dart';
import 'donate_screen.dart';
import 'qurbani_guide_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

// ─── TINTS (match the React dashboard's Tailwind tones) ──────────────

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
  static const Color blue300 = Color(0xFF93C5FD);

  static const _Tone amber = _Tone(
    bg: Color(0xFFFFFBEB),
    bg2: Color(0xFFFEF3C7),
    border: Color(0xFFFDE68A),
    from: Color(0xFFFCD34D),
    to: AppColors.accentDark,
    fg: Color(0xFFB45309),
  );

  static const _Tone blue = _Tone(
    bg: Color(0xFFEFF6FF),
    bg2: Color(0xFFDBEAFE),
    border: Color(0xFFBFDBFE),
    from: Color(0xFF60A5FA),
    to: Color(0xFF2563EB),
    fg: Color(0xFF1D4ED8),
  );

  static const _Tone rose = _Tone(
    bg: Color(0xFFFFF1F2),
    bg2: Color(0xFFFFE4E6),
    border: Color(0xFFFECDD3),
    from: Color(0xFFFB7185),
    to: Color(0xFFE11D48),
    fg: Color(0xFFBE123C),
  );

  static const _Tone emerald = _Tone(
    bg: AppColors.primaryBg,
    bg2: AppColors.primaryLight,
    border: AuthColors.emerald200,
    from: AuthColors.emerald400,
    to: AppColors.primaryDark,
    fg: AuthColors.emerald700,
  );
}

// ─── SHELL ───────────────────────────────────

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeContent(),
    MyRequestsScreen(),
    QurbaniCalculatorScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: false,
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    const radius = BorderRadius.vertical(top: Radius.circular(28));

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF0FDF4)],
        ),
        borderRadius: radius,
        border: Border(
          top: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald900.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primaryLight,
          indicatorShape: const StadiumBorder(),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate_rounded),
              label: 'Calculator',
            ),
            NavigationDestination(
              icon: _NavIconWithBadge(icon: Icons.notifications_none_rounded),
              selectedIcon:
                  _NavIconWithBadge(icon: Icons.notifications_rounded),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  final IconData icon;
  const _NavIconWithBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── HOME CONTENT ──────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const double _statsOverlap = 64;
  static const double _statsHeight = 118;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String? _userName;
  Map<String, int> _stats = {'pending': 0, 'assigned': 0, 'completed': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.user!.uid)
        .get();
    setState(() {
      _userName = userDoc.data()?['name'] as String?;
    });

    final requestsSnap = await FirebaseFirestore.instance
        .collection('pickupRequests')
        .where('userId', isEqualTo: auth.user!.uid)
        .get();

    int pending = 0, assigned = 0, completed = 0;
    for (var doc in requestsSnap.docs) {
      final status = doc.data()['status'] as String? ?? '';
      if (status == 'pending') pending++;
      if (status == 'assigned') assigned++;
      if (status == 'completed') completed++;
    }

    if (mounted) {
      setState(() {
        _stats = {
          'pending': pending,
          'assigned': assigned,
          'completed': completed
        };
      });
    }
  }

  String _todayLabel() {
    final d = DateTime.now();
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AuthSystemUi(
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackdrop()),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 26),
                      _Reveal(index: 4, child: _buildSummaryCard()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── BACKDROP (tinted page, never flat white) ─────────

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
          bottom: 120,
          left: -150,
          child: GlowCircle(
            size: 320,
            color: AppColors.accent.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─── HEADER ──────────────────────────────────

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHero(top),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: -_statsOverlap,
              child: _buildStatsRow(),
            ),
          ],
        ),
        const SizedBox(height: _statsOverlap),
      ],
    );
  }

  Widget _buildHero(double top) {
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
          // lattice, fading out toward the left (like the React hero)
          const Positioned.fill(child: _MaskedLattice()),
          // amber glow, top-right
          Positioned(
            top: -90,
            right: -60,
            child: GlowCircle(
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.50),
            ),
          ),
          // teal glow, bottom
          Positioned(
            bottom: -110,
            left: 40,
            child: GlowCircle(
              size: 280,
              color: const Color(0xFF5EEAD4).withValues(alpha: 0.22),
            ),
          ),
          // crescent watermark
          Positioned(
            top: top + 58,
            right: -34,
            child: Icon(
              Icons.nightlight_round,
              size: 200,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          // glowing amber crescent
          Positioned(
            top: top + 76,
            right: 30,
            child: Transform.rotate(
              angle: 0.32,
              child: Icon(
                Icons.nightlight_round,
                size: 54,
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
            right: 100,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: _Tones.amber300.withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            top: top + 150,
            right: 18,
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          // content
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, _statsOverlap + 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AuthHeroChip(
                      icon: Icons.calendar_today_rounded,
                      label: _todayLabel(),
                    ),
                    const Spacer(),
                    _buildCircleIconWithBadge(
                      Icons.notifications_none_rounded,
                      showBadge: true,
                    ),
                    const SizedBox(width: 10),
                    _buildCircleIcon(Icons.person_outline_rounded),
                  ],
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(right: 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السلام عليكم',
                        style: AppTextStyles.body.copyWith(
                          color: AuthColors.emerald200.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome, ${_userName ?? 'Hifza'}!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Eid Mubarak! ',
                              style: AppTextStyles.body.copyWith(
                                color: _Tones.amber300,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'Keep Abbottabad clean this Eid.',
                              style: AppTextStyles.body.copyWith(
                                color: AuthColors.emerald200
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _GradientButton(
                        label: 'Book Pickup',
                        icon: Icons.local_shipping_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookPickupScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: _GlassButton(
                        label: 'Guide',
                        icon: Icons.menu_book_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QurbaniGuideScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildSearchBar(),
              ],
            ),
          ),
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
            child: Text(
              'Search for pickup or guide...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child:
                const Icon(Icons.tune_rounded, size: 17, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }

  Widget _buildCircleIconWithBadge(IconData icon, {bool showBadge = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCircleIcon(icon),
        if (showBadge)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: AuthColors.emerald700, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ─── STAT CARDS (tinted, overlapping the hero) ────────

  Widget _buildStatsRow() {
    return SizedBox(
      height: _statsHeight,
      child: Row(
        children: [
          Expanded(
            child: _Reveal(
              index: 0,
              child: _StatCard(
                label: 'Pending',
                value: _stats['pending'] ?? 0,
                icon: Icons.hourglass_top_rounded,
                tone: _Tones.amber,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Reveal(
              index: 1,
              child: _StatCard(
                label: 'Assigned',
                value: _stats['assigned'] ?? 0,
                icon: Icons.local_shipping_rounded,
                tone: _Tones.blue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Reveal(
              index: 2,
              child: _StatCard(
                label: 'Completed',
                value: _stats['completed'] ?? 0,
                icon: Icons.check_circle_rounded,
                tone: _Tones.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS ──────────────────────────

  void _openAction(Map<String, dynamic> action) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => action['screen'] as Widget),
    );
  }

  Widget _buildSectionHeader(String title, String caption) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(caption, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [
      {
        'icon': Icons.calculate_rounded,
        'label': 'Qurbani Guide',
        'subtitle': 'Meat Calculator',
        'tone': _Tones.amber,
        'screen': const QurbaniCalculatorScreen(),
      },
      {
        'icon': Icons.local_shipping_rounded,
        'label': 'Book Pickup',
        'subtitle': 'Schedule Waste Collection',
        'screen': const BookPickupScreen(),
      },
      {
        'icon': Icons.favorite_rounded,
        'label': 'Donate to NGO',
        'subtitle': 'Support Verified Orgs',
        'tone': _Tones.rose,
        'screen': const DonateScreen(),
      },
      {
        'icon': Icons.menu_book_rounded,
        'label': 'Educational Guide',
        'subtitle': 'Hygiene & Islamic Rules',
        'tone': _Tones.blue,
        'screen': const QurbaniGuideScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick actions', 'Everything you need this Eid'),
        const SizedBox(height: 16),
        _Reveal(index: 1, child: _buildFeaturedAction(actions[1])),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Reveal(index: 2, child: _buildActionTile(actions[0])),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _Reveal(index: 3, child: _buildActionTile(actions[3])),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Reveal(index: 3, child: _buildWideAction(actions[2])),
      ],
    );
  }

  Widget _buildGradientIconTile(IconData icon, _Tone tone, {double size = 44}) {
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
          Icon(icon, color: Colors.white, size: size * 0.5),
        ],
      ),
    );
  }

  Widget _buildArrowChip(_Tone tone) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: tone.bg2,
        shape: BoxShape.circle,
        border: Border.all(color: tone.border),
      ),
      child: Icon(Icons.arrow_forward_rounded, size: 15, color: tone.to),
    );
  }

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

  Widget _buildFeaturedAction(Map<String, dynamic> action) {
    return _PressScale(
      onTap: () => _openAction(action),
      child: Container(
        height: 170,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              AuthColors.emerald700,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.42),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AuthColors.emerald900.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _MaskedLattice(alpha: 0.12)),
            Positioned(
              top: -70,
              right: -50,
              child: GlowCircle(
                size: 240,
                color: AppColors.accent.withValues(alpha: 0.50),
              ),
            ),
            Positioned(
              bottom: -26,
              right: 56,
              child: Icon(
                Icons.nightlight_round,
                size: 120,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AuthLogoTile(
                            icon: action['icon'] as IconData,
                            size: 48,
                            radius: 16,
                            iconSize: 24,
                            ringColor: AppColors.primaryDark,
                            crescentBadge: true,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action['label'] as String,
                                style: AppTextStyles.h2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                action['subtitle'] as String,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFCD34D), AppColors.accent],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.55),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AuthColors.emerald950,
                        size: 23,
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

  Widget _buildActionTile(Map<String, dynamic> action) {
    final tone = action['tone'] as _Tone;

    return _PressScale(
      onTap: () => _openAction(action),
      child: Container(
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: _tintedCardDecoration(tone, 24),
        child: Stack(
          children: [
            Positioned(
              top: -34,
              right: -30,
              child: GlowCircle(
                size: 130,
                color: tone.from.withValues(alpha: 0.45),
              ),
            ),
            Positioned(
              right: -22,
              bottom: -22,
              child: Icon(
                action['icon'] as IconData,
                size: 108,
                color: tone.to.withValues(alpha: 0.09),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildGradientIconTile(
                          action['icon'] as IconData,
                          tone,
                        ),
                        const Spacer(),
                        _buildArrowChip(tone),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      action['label'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action['subtitle'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: tone.fg,
                        fontWeight: FontWeight.w600,
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

  Widget _buildWideAction(Map<String, dynamic> action) {
    final tone = action['tone'] as _Tone;

    return _PressScale(
      onTap: () => _openAction(action),
      child: Container(
        height: 92,
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
              right: 44,
              top: -12,
              child: Icon(
                action['icon'] as IconData,
                size: 104,
                color: tone.to.withValues(alpha: 0.08),
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
                    _buildGradientIconTile(
                      action['icon'] as IconData,
                      tone,
                      size: 54,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['label'] as String,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action['subtitle'] as String,
                            style: AppTextStyles.caption.copyWith(
                              color: tone.fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildArrowChip(tone),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

  // ─── TODAY'S SUMMARY (dark lattice card, like the React side card) ────

  Widget _buildSummaryCard() {
    final pending = _stats['pending'] ?? 0;
    final assigned = _stats['assigned'] ?? 0;
    final completed = _stats['completed'] ?? 0;
    final total = pending + assigned + completed;
    final double progress = total == 0 ? 0.0 : completed / total;
    final int pct = (progress * 100).round();

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
                        Icons.event_note_rounded,
                        size: 21,
                        color: AuthColors.emerald200,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Summary",
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Your pickups so far',
                          style: AppTextStyles.caption.copyWith(
                            color: AuthColors.emerald200.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryRow(
                  Icons.hourglass_top_rounded,
                  _Tones.amber300,
                  'Pending',
                  pending,
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  Icons.local_shipping_rounded,
                  _Tones.blue300,
                  'Assigned',
                  assigned,
                ),
                const SizedBox(height: 8),
                _summaryRow(
                  Icons.check_circle_rounded,
                  AuthColors.emerald300,
                  'Completed',
                  completed,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      size: 15,
                      color: _Tones.amber300,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Completion rate',
                        style: AppTextStyles.caption.copyWith(
                          color: AuthColors.emerald200.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _Tones.amber200,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: v.clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_Tones.amber300, AppColors.accent],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: AuthColors.emerald200.withValues(alpha: 0.9),
              ),
            ),
          ),
          Text(
            '$value',
            style: AppTextStyles.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STAT CARD ─────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final _Tone tone;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.bg, tone.bg2],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -34,
            right: -30,
            child: GlowCircle(
              size: 100,
              color: tone.from.withValues(alpha: 0.50),
            ),
          ),
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    tone.to.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tone.from, tone.to],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tone.to.withValues(alpha: 0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
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
                        height: 18,
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
                      Icon(icon, size: 19, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) {
                    return Text(
                      '$v',
                      style: AppTextStyles.stat.copyWith(
                        fontSize: 28,
                        color: tone.fg,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tone.fg.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REUSABLE VISUAL PIECES ────────────────────

/// Star lattice that fades out toward the left (mirrors the React hero mask).
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

/// Emerald-400 to emerald-600 gradient CTA with gloss and coloured shadow.
class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
          height: 48,
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
                    .withValues(alpha: _pressed ? 0.25 : 0.50),
                blurRadius: _pressed ? 10 : 22,
                offset: Offset(0, _pressed ? 3 : 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 24,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                        fontSize: 14.5,
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

/// Frosted glass secondary button for use on the dark hero.
class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.22 : 0.12),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: _Tones.amber200),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scales its child down slightly while pressed.
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

/// Fade + slide-up entrance, staggered by [index].
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
