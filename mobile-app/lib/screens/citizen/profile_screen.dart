// 📁 lib/screens/citizen/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import '../auth/login_screen.dart';
import 'my_requests_screen.dart';

// ─── TINTS (same tones as the React dashboard) ──────────────

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

  static final _Tone indigo = _Tone(
    bg: const Color(0xFFEEF2FF),
    bg2: const Color(0xFFE0E7FF),
    border: const Color(0xFFC7D2FE),
    from: const Color(0xFF818CF8),
    to: const Color(0xFF4F46E5),
    fg: const Color(0xFF4338CA),
  );
}

// ─── SCREEN ────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _statsOverlap = 64;
  static const double _statsHeight = 118;

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
  String? _phone;
  Map<String, int> _stats = {'pending': 0, 'assigned': 0, 'completed': 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Same reads as the citizen home screen (users doc + pickupRequests counts).
  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userName = userDoc.data()?['name'] as String?;
          _phone = userDoc.data()?['phone'] as String?;
        });
      }

      final requestsSnap = await FirebaseFirestore.instance
          .collection('pickupRequests')
          .where('userId', isEqualTo: user.uid)
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
            'completed': completed,
          };
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final top = MediaQuery.of(context).padding.top;

    final fetchedName = _userName?.trim() ?? '';
    final displayName =
        fetchedName.isNotEmpty ? fetchedName : (user?.displayName ?? 'User');
    final email = user?.email ?? 'user@email.com';
    final created = user?.metadata.creationTime;
    final phone = _phone?.trim() ?? '';

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(
                    top: top,
                    displayName: displayName,
                    email: email,
                    created: created,
                    phone: phone,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _Reveal(index: 3, child: _buildMenu()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────

  Widget _buildHeader({
    required double top,
    required String displayName,
    required String email,
    required DateTime? created,
    required String phone,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHero(
              top: top,
              displayName: displayName,
              email: email,
              created: created,
              phone: phone,
            ),
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

  Widget _buildHero({
    required double top,
    required String displayName,
    required String email,
    required DateTime? created,
    required String phone,
  }) {
    final trimmed = displayName.trim();
    final initial = trimmed.isEmpty
        ? 'U'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();

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
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, _statsOverlap + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeroChip(
                  icon: Icons.person_rounded,
                  label: 'MY ACCOUNT',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildAvatar(initial),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 56),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                color: AuthColors.emerald200
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                            if (created != null || phone.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (created != null)
                                    _InfoPill(
                                      icon: Icons.verified_rounded,
                                      label:
                                          'Since ${_months[created.month - 1]} ${created.year}',
                                    ),
                                  if (phone.isNotEmpty)
                                    _InfoPill(
                                      icon: Icons.phone_rounded,
                                      label: phone,
                                    ),
                                ],
                              ),
                            ],
                          ],
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
    );
  }

  Widget _buildAvatar(String initial) {
    return Container(
      width: 84,
      height: 84,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Tones.amber300, AuthColors.emerald300],
        ),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald950.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AuthColors.emerald400, AppColors.primaryDark],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: AppTextStyles.h1.copyWith(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

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

  // ─── MENU ────────────────────────────────────

  // Rows with `onTap: () {}` keep the same no-op placeholder taps as before.
  Widget _buildMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MenuGroup(
          title: 'Account',
          icon: Icons.manage_accounts_rounded,
          tone: _Tones.emerald,
          rows: [
            _MenuRow(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              tone: _Tones.emerald,
              onTap: () {},
            ),
            _MenuRow(
              icon: Icons.receipt_long_rounded,
              title: 'My Requests',
              tone: _Tones.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                );
              },
            ),
            _MenuRow(
              icon: Icons.favorite_rounded,
              title: 'Donation History',
              tone: _Tones.rose,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 22),
        _MenuGroup(
          title: 'Preferences',
          icon: Icons.tune_rounded,
          tone: _Tones.indigo,
          rows: [
            _MenuRow(
              icon: Icons.bookmark_rounded,
              title: 'Saved Guides',
              tone: _Tones.amber,
              onTap: () {},
            ),
            _MenuRow(
              icon: Icons.settings_rounded,
              title: 'Settings',
              tone: _Tones.indigo,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 22),
        _MenuGroup(
          title: 'Support',
          icon: Icons.support_agent_rounded,
          tone: _Tones.blue,
          rows: [
            _MenuRow(
              icon: Icons.help_rounded,
              title: 'Help & Support',
              tone: _Tones.blue,
              onTap: () {},
            ),
            _MenuRow(
              icon: Icons.star_rounded,
              title: 'Rate App',
              tone: _Tones.amber,
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 26),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final tone = _Tones.rose;

    return _PressScale(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tone.bg, tone.bg2],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tone.border, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: tone.to.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: GlowCircle(
                size: 120,
                color: tone.from.withValues(alpha: 0.40),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 20, color: tone.fg),
                const SizedBox(width: 10),
                Text(
                  'Logout',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: tone.fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MENU WIDGETS ──────────────────────────────

class _MenuGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final _Tone tone;
  final List<Widget> rows;

  const _MenuGroup({
    required this.title,
    required this.icon,
    required this.tone,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 16),
            child: Container(height: 1, color: AppColors.slate100),
          ),
        );
      }
      children.add(rows[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _GradientTile(icon: icon, tone: tone, size: 32),
            const SizedBox(width: 10),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tone.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: tone.to.withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final _Tone tone;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _GradientTile(icon: icon, tone: tone, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
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
                Icons.chevron_right_rounded,
                size: 18,
                color: tone.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD (matches citizen_home) ──────────

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
                _GradientTile(icon: icon, tone: tone, size: 36),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

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
          Icon(icon, size: 12, color: _Tones.amber300),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REUSABLE VISUAL PIECES ────────────────────

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
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
}

class _GradientTile extends StatelessWidget {
  final IconData icon;
  final _Tone tone;
  final double size;
  const _GradientTile({
    required this.icon,
    required this.tone,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
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
            color: tone.to.withValues(alpha: 0.38),
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
}

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
