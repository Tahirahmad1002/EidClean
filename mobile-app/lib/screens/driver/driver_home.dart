// lib/screens/driver/driver_home.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../auth/login_screen.dart';
import 'driver_task_detail.dart';
import 'optimize_route_screen.dart';
import 'active_route_screen.dart';

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
  static const Color blue300 = Color(0xFF93C5FD);

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

  static final _Tone indigo = _Tone(
    bg: const Color(0xFFEEF2FF),
    bg2: const Color(0xFFE0E7FF),
    border: const Color(0xFFC7D2FE),
    from: const Color(0xFF818CF8),
    to: const Color(0xFF4F46E5),
    fg: const Color(0xFF4338CA),
  );

  static final _Tone slate = _Tone(
    bg: const Color(0xFFF8FAFC),
    bg2: const Color(0xFFF1F5F9),
    border: const Color(0xFFE2E8F0),
    from: const Color(0xFF94A3B8),
    to: const Color(0xFF475569),
    fg: const Color(0xFF334155),
  );
}

// ─── SHELL ───────────────────────────────────────────────────────────

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentIndex == 0 ? const _DashboardTab() : const _ProfileTab(),
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
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
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

// ─── DASHBOARD TAB ───────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  static const double _statsOverlap = 64;
  static const double _statsHeight = 118;

  String _filter = 'all';
  bool _isRouteOptimized = false;
  List<String> _optimizedSequence = [];
  int _pendingCount = 0;
  String? _driverName;

  StreamSubscription<DocumentSnapshot>? _driverSub;
  bool _reoptimizationPromptShown = false;

  @override
  void initState() {
    super.initState();
    _loadDriverName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToDriverDoc();
    });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverName() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.user!.uid)
            .get();
        if (!mounted) return;
        setState(() {
          _driverName = doc.data()?['name'] as String?;
        });
      } catch (e) {
        debugPrint('[DriverHome] Error loading name: $e');
      }
    }
  }

  // ─── DRIVER DOC LISTENER ──────────────────────

  void _listenToDriverDoc() {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    _driverSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final sequence = data['optimizedSequence'];
      if (sequence is List && sequence.isNotEmpty) {
        // Validate sequence — only keep IDs of pending tasks
        try {
          final pendingSnap = await FirebaseFirestore.instance
              .collection('pickupRequests')
              .where('driverId', isEqualTo: uid)
              .where('status',
                  whereIn: ['assigned', 'arrived', 'on_the_way']).get();

          final pendingIds = pendingSnap.docs.map((d) => d.id).toSet();
          final validSequence = sequence
              .map((e) => e.toString())
              .where((id) => pendingIds.contains(id))
              .toList();

          if (validSequence.isEmpty) {
            // Stale sequence — clear it
            debugPrint('[DriverHome] Stale sequence detected — clearing');
            await FirebaseFirestore.instance
                .collection('drivers')
                .doc(uid)
                .update({'optimizedSequence': []});
            if (mounted) {
              setState(() {
                _isRouteOptimized = false;
                _optimizedSequence = [];
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _isRouteOptimized = true;
                _optimizedSequence = validSequence;
              });
            }
          }
        } catch (e) {
          debugPrint('[DriverHome] Sequence validation error: $e');
          // Fallback: trust the sequence
          if (mounted) {
            setState(() {
              _isRouteOptimized = true;
              _optimizedSequence = sequence.map((e) => e.toString()).toList();
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isRouteOptimized = false;
            _optimizedSequence = [];
          });
        }
      }

      _checkReoptimizationFlag(uid);
    });
  }

  Future<void> _checkReoptimizationFlag(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pickupRequests')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .where('routeNeedsReoptimization', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty && !_reoptimizationPromptShown && mounted) {
        _reoptimizationPromptShown = true;
        _showReoptimizeDialog();
      }
    } catch (e) {
      debugPrint('[DriverHome] Flag check error: $e');
    }
  }

  void _showReoptimizeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF0FDF4)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _Tones.emerald.border),
            boxShadow: [
              BoxShadow(
                color: AuthColors.emerald950.withValues(alpha: 0.30),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _gradientTile(Icons.auto_awesome_rounded, _Tones.amber,
                      size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Route Update Available',
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'A pickup was completed. Optimize the remaining route for the best sequence?',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.slate600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PressScale(
                      onTap: () {
                        Navigator.pop(ctx);
                        _reoptimizationPromptShown = false;
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _Tones.slate.bg2,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(color: _Tones.slate.border),
                        ),
                        child: Text(
                          'Later',
                          style: AppTextStyles.button.copyWith(
                            color: _Tones.slate.fg,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6 ~/ 5 + 1,
                    child: _ToneButton(
                      label: 'Optimize Now',
                      icon: Icons.auto_awesome_rounded,
                      tone: _Tones.emerald,
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateRoute();
                      },
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

  // ─── ACTIONS ──────────────────────────────────

  Future<void> _generateRoute() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const OptimizeRouteScreen(),
      ),
    );
    if (result == true && mounted) {
      setState(() => _isRouteOptimized = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route accepted — follow the sequence'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate directly to active route for immediate action
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActiveRouteScreen()),
      );
    }
  }

  void _openActiveRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveRouteScreen()),
    );
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSystemUi(
      child: Stack(
        children: [
          Positioned.fill(child: _buildBackdrop()),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(auth),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Reveal(index: 3, child: _buildOptimizationCard()),
                        const SizedBox(height: 26),
                        _Reveal(
                          index: 4,
                          child: _sectionHeader(
                            'Tasks Details',
                            'Your assigned pickups',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFilterChips(),
                        const SizedBox(height: 14),
                        _buildTaskList(auth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  // ─── HEADER ───────────────────────────────────

  Widget _buildHeader(AuthProvider auth) {
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
              child: _buildStatsRow(auth),
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
            top: top + 58,
            right: -34,
            child: Icon(
              Icons.nightlight_round,
              size: 200,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
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
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, _statsOverlap + 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AuthHeroChip(
                      icon: Icons.calendar_today_rounded,
                      label: _getFormattedDate().toUpperCase(),
                    ),
                    const Spacer(),
                    _circleIcon(Icons.notifications_none_rounded),
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
                        'Welcome back, ${_driverName ?? 'Driver'}!',
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
                              text: 'Keep Abbottabad clean today.',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
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

  // ─── STATS ────────────────────────────────────

  Widget _buildStatsRow(AuthProvider auth) {
    return SizedBox(
      height: _statsHeight,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pickupRequests')
            .where('driverId', isEqualTo: auth.user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int? total;
          int? pending;
          int? done;

          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            total = docs.length;
            done = docs
                .where((d) => (d.data() as Map)['status'] == 'completed')
                .length;
            final p = docs.where((d) {
              final s = (d.data() as Map)['status'] ?? '';
              return s == 'assigned' || s == 'arrived' || s == 'on_the_way';
            }).length;
            pending = p;

            // Update pending count for banner
            if (_pendingCount != p) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _pendingCount = p);
              });
            }
          }

          return Row(
            children: [
              Expanded(
                child: _Reveal(
                  index: 0,
                  child: _StatCard(
                    label: 'Total',
                    value: total,
                    icon: Icons.list_alt_rounded,
                    tone: _Tones.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Reveal(
                  index: 1,
                  child: _StatCard(
                    label: 'Pending',
                    value: pending,
                    icon: Icons.hourglass_top_rounded,
                    tone: _Tones.amber,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Reveal(
                  index: 2,
                  child: _StatCard(
                    label: 'Done',
                    value: done,
                    icon: Icons.check_circle_rounded,
                    tone: _Tones.emerald,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── OPTIMIZATION CARD ────────────────────────

  Widget _buildOptimizationCard() {
    final remaining = _optimizedSequence.length;

    return _PressScale(
      onTap: _isRouteOptimized ? _openActiveRoute : _generateRoute,
      child: Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AuthLogoTile(
                        icon: _isRouteOptimized
                            ? Icons.navigation_rounded
                            : Icons.route_rounded,
                        size: 48,
                        radius: 16,
                        iconSize: 24,
                        ringColor: AppColors.primaryDark,
                        crescentBadge: true,
                      ),
                      const Spacer(),
                      if (_isRouteOptimized)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _Tones.amber300,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _Tones.amber300
                                          .withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$remaining left',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRouteOptimized
                        ? 'Active Route'
                        : 'AI Route Optimization',
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRouteOptimized
                        ? 'Continue where you left off — next pickup is waiting'
                        : 'Get the fastest route for all pickups today',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFCD34D), AppColors.accent],
                      ),
                      borderRadius: AppRadius.lgAll,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRouteOptimized
                              ? Icons.navigation_rounded
                              : Icons.auto_awesome_rounded,
                          size: 18,
                          color: AuthColors.emerald950,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRouteOptimized
                              ? 'Continue Route'
                              : 'Generate Optimized Route',
                          style: AppTextStyles.button.copyWith(
                            color: AuthColors.emerald950,
                            fontSize: 14.5,
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

  // ─── FILTERS ──────────────────────────────────

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('All', 'all', Icons.apps_rounded),
          const SizedBox(width: 8),
          _filterChip('Pending', 'assigned', Icons.hourglass_top_rounded),
          const SizedBox(width: 8),
          _filterChip('Done', 'completed', Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final selected = _filter == value;
    final tone = _Tones.emerald;

    return _PressScale(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
            Icon(icon, size: 15, color: selected ? Colors.white : tone.to),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : tone.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TASK LIST ────────────────────────────────

  Widget _buildTaskList(AuthProvider auth) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pickupRequests')
          .where('driverId', isEqualTo: auth.user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _messageCard(
            Icons.error_outline_rounded,
            _Tones.rose,
            'Error loading tasks',
            '${snapshot.error}',
          );
        }

        final docs = snapshot.data!.docs;

        // Filter
        var filteredDocs = docs;
        if (_filter == 'assigned') {
          filteredDocs = docs.where((d) {
            final status = (d.data() as Map)['status'] ?? '';
            return status == 'assigned' || status == 'arrived';
          }).toList();
        } else if (_filter == 'completed') {
          filteredDocs = docs.where((d) {
            final status = (d.data() as Map)['status'] ?? '';
            return status == 'completed';
          }).toList();
        }

        // Sort: active first, then by status priority
        filteredDocs = filteredDocs.toList()
          ..sort((a, b) {
            final statusA = (a.data() as Map)['status'] ?? '';
            final statusB = (b.data() as Map)['status'] ?? '';

            int getPriority(String status) {
              if (status == 'on_the_way') return 0;
              if (status == 'assigned') return 1;
              if (status == 'arrived') return 2;
              if (status == 'completed') return 3;
              return 4;
            }

            return getPriority(statusA).compareTo(getPriority(statusB));
          });

        if (filteredDocs.isEmpty) {
          String message = 'No tasks';
          if (_filter == 'assigned') message = 'No pending tasks';
          if (_filter == 'completed') message = 'No completed tasks';

          return _messageCard(
            Icons.assignment_turned_in_rounded,
            _Tones.emerald,
            message,
            'New assignments will show up here.',
          );
        }

        return Column(
          children: [
            for (int i = 0; i < filteredDocs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Reveal(
                  index: i < 4 ? i + 4 : 8,
                  child: Builder(
                    builder: (_) {
                      final doc = filteredDocs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'pending';
                      final isCompleted = status == 'completed';
                      final seqIndex = _optimizedSequence.indexOf(doc.id);

                      return _buildTaskCard(
                        docId: doc.id,
                        data: data,
                        isCompleted: isCompleted,
                        priority: _getPriority(data),
                        sequenceNumber: seqIndex >= 0 ? seqIndex + 1 : null,
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _messageCard(IconData icon, _Tone tone, String title, String sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _tintedCardDecoration(tone, 24),
      child: Row(
        children: [
          _gradientTile(icon, tone, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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

  // ─── TASK CARD ────────────────────────────────

  Widget _buildTaskCard({
    required String docId,
    required Map<String, dynamic> data,
    required bool isCompleted,
    required int priority,
    int? sequenceNumber,
  }) {
    final location = data['location'] ?? 'No location';
    final userName = data['userName'] ?? 'Customer';
    final animals = data['animals'] ?? 1;
    final wasteType = (data['wasteType'] ?? 'mixed').toString();
    final status = (data['status'] ?? 'assigned').toString();

    final isActive = status == 'on_the_way';
    final tone = _statusTone(status);
    final pTone = _priorityTone(priority);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _tintedCardDecoration(tone, 24).copyWith(
        border: Border.all(
          color: isActive ? tone.to : tone.border,
          width: isActive ? 2 : 1.3,
        ),
      ),
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
            bottom: -22,
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.local_shipping_rounded,
              size: 108,
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
                    if (sequenceNumber != null && !isCompleted) ...[
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_Tones.blue.from, _Tones.blue.to],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _Tones.blue.to.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$sequenceNumber',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _pill('P$priority', pTone),
                    const SizedBox(width: 8),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tone.to,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _statusLabel(status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: tone.fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isCompleted && data['timeSlot'] != null)
                      _pill(
                        data['timeSlot'].toString().split(' ')[0],
                        _Tones.emerald,
                        icon: Icons.schedule_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _gradientTile(Icons.person_rounded, tone, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: tone.to,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  '$location',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.slate600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill(
                      '$animals Animal${animals > 1 ? 's' : ''}',
                      _Tones.amber,
                      icon: Icons.pets_rounded,
                    ),
                    ..._getWasteChips(wasteType),
                  ],
                ),
                const SizedBox(height: 14),
                if (!isCompleted)
                  _ToneButton(
                    label: isActive ? 'Continue Task' : 'Start Pickup',
                    icon: isActive
                        ? Icons.play_arrow_rounded
                        : Icons.local_shipping_rounded,
                    tone: isActive ? _Tones.amber : _Tones.emerald,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverTaskDetail(
                            taskId: docId,
                            taskData: data,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tone.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: tone.to, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: AppTextStyles.label.copyWith(
                            color: tone.fg,
                            fontWeight: FontWeight.w800,
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

  // ─── HELPERS ──────────────────────────────────

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
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
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  int _getPriority(Map<String, dynamic> data) {
    final animals = data['animals'] ?? 1;
    if (animals >= 3) return 1;
    if (animals >= 2) return 2;
    return 3;
  }

  _Tone _priorityTone(int priority) {
    switch (priority) {
      case 1:
        return _Tones.rose;
      case 2:
        return _Tones.amber;
      default:
        return _Tones.emerald;
    }
  }

  _Tone _statusTone(String status) {
    switch (status) {
      case 'on_the_way':
        return _Tones.amber;
      case 'arrived':
        return _Tones.indigo;
      case 'completed':
        return _Tones.emerald;
      default:
        return _Tones.blue;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'on_the_way':
        return 'On the way';
      case 'arrived':
        return 'Arrived';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  List<Widget> _getWasteChips(String wasteType) {
    final types = wasteType.split(',').map((e) => e.trim()).toList();
    if (types.isEmpty || (types.length == 1 && types.first.isEmpty)) {
      return [_buildWasteChip(wasteType)];
    }
    return types.map((type) => _buildWasteChip(type)).toList();
  }

  Widget _buildWasteChip(String type) {
    final tones = <String, _Tone>{
      'skin': _Tones.amber,
      'bones': _Tones.blue,
      'offal': _Tones.rose,
      'blood': _Tones.rose,
      'mixed': _Tones.emerald,
    };
    return _pill(type, tones[type] ?? _Tones.slate);
  }

  Widget _pill(String text, _Tone tone, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.to),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: tone.fg,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String caption) {
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
}

// ─── PROFILE TAB ─────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final top = MediaQuery.of(context).padding.top;

    return AuthSystemUi(
      child: Stack(
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
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHero(top, user?.displayName ?? 'Driver',
                    user?.email ?? 'driver@eidclean.com'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  child: Column(
                    children: [
                      _Reveal(index: 0, child: _buildStatsCard()),
                      const SizedBox(height: 28),
                      _Reveal(
                        index: 1,
                        child: _ToneButton(
                          label: 'Logout',
                          icon: Icons.logout_rounded,
                          tone: _Tones.rose,
                          height: 54,
                          onTap: () async {
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (_) => false,
                              );
                            }
                          },
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

  Widget _buildHero(double top, String name, String email) {
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
            top: top + 40,
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
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 28),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AuthHeroChip(
                    icon: Icons.badge_rounded,
                    label: 'DRIVER PROFILE',
                  ),
                ),
                const SizedBox(height: 22),
                AuthLogoTile(
                  icon: Icons.person_rounded,
                  size: 84,
                  radius: 28,
                  iconSize: 42,
                  ringColor: AuthColors.emerald900,
                  crescentBadge: true,
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.body.copyWith(
                    color: AuthColors.emerald200.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                const AuthHeroChip(
                  icon: Icons.local_shipping_rounded,
                  label: 'DRIVER',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Tones.emerald.bg, _Tones.emerald.bg2],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Tones.emerald.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: _Tones.emerald.to.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _profileStat(
                'Total Tasks', '0', Icons.list_alt_rounded, _Tones.indigo),
            _profileDivider(),
            _profileStat(
                'Completed', '0', Icons.check_circle_rounded, _Tones.emerald),
            _profileDivider(),
            _profileStat('Rating', '5.0', Icons.star_rounded, _Tones.amber),
          ],
        ),
      ),
    );
  }

  Widget _profileStat(String label, String value, IconData icon, _Tone tone) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: tone.to),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.stat.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: tone.fg,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: tone.fg.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: _Tones.emerald.border,
    );
  }
}

// ─── SHARED GRADIENT TILE ────────────────────────────────────────────

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

// ─── STAT CARD ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int? value;
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gradientTile(icon, tone, size: 36),
                const Spacer(),
                if (value == null)
                  Text(
                    '--',
                    style: AppTextStyles.stat.copyWith(
                      fontSize: 28,
                      color: tone.fg,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value!),
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

/// Tone-coloured gradient button with gloss and coloured shadow.
class _ToneButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _Tone tone;
  final VoidCallback onTap;
  final double height;

  const _ToneButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.height = 48,
  });

  @override
  State<_ToneButton> createState() => _ToneButtonState();
}

class _ToneButtonState extends State<_ToneButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;

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
        child: Container(
          height: widget.height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [tone.from, tone.to],
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: tone.to.withValues(alpha: _pressed ? 0.25 : 0.45),
                blurRadius: _pressed ? 10 : 20,
                offset: Offset(0, _pressed ? 3 : 9),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height / 2,
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
