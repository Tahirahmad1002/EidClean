// 📁 lib/screens/citizen/notifications_screen.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';

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
}

// ─── NOTIFICATION MODEL (local, UI-only) ────────

enum _NotifType { confirmed, driver, completed, donation, feature }

class _Notif {
  final _NotifType type;
  final String title;
  final String subtitle;
  final String time;
  bool unread;

  _Notif({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
  });
}

_Tone _toneFor(_NotifType type) {
  switch (type) {
    case _NotifType.confirmed:
      return _Tones.emerald;
    case _NotifType.driver:
      return _Tones.blue;
    case _NotifType.completed:
      return _Tones.emerald;
    case _NotifType.donation:
      return _Tones.rose;
    case _NotifType.feature:
      return _Tones.amber;
  }
}

IconData _iconFor(_NotifType type) {
  switch (type) {
    case _NotifType.confirmed:
      return Icons.check_circle_rounded;
    case _NotifType.driver:
      return Icons.local_shipping_rounded;
    case _NotifType.completed:
      return Icons.done_all_rounded;
    case _NotifType.donation:
      return Icons.favorite_rounded;
    case _NotifType.feature:
      return Icons.new_releases_rounded;
  }
}

// ─── SCREEN ────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Same sample notifications as before. The unread flags are local UI state:
  // "Mark all read" and tapping a card clear them.
  final List<_Notif> _items = [
    _Notif(
      type: _NotifType.confirmed,
      title: 'Pickup Confirmed',
      subtitle: 'Your pickup is scheduled for tomorrow at 9 AM',
      time: '2 hours ago',
      unread: true,
    ),
    _Notif(
      type: _NotifType.driver,
      title: 'Driver Assigned',
      subtitle: 'Ali has been assigned to your pickup #EID-12345',
      time: '5 hours ago',
      unread: true,
    ),
    _Notif(
      type: _NotifType.completed,
      title: 'Pickup Completed',
      subtitle: 'Thank you for using EidClean. Your feedback helps us improve!',
      time: '1 day ago',
    ),
    _Notif(
      type: _NotifType.donation,
      title: 'Donation Accepted',
      subtitle: 'Edhi Foundation accepted your donation of 10 kg meat',
      time: '2 days ago',
    ),
    _Notif(
      type: _NotifType.feature,
      title: 'New Feature Available',
      subtitle: 'Check out our new Meat Calculator for better planning',
      time: '3 days ago',
    ),
  ];

  int get _unreadCount => _items.where((n) => n.unread).length;

  void _markAllRead() {
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  void _markRead(_Notif n) {
    if (!n.unread) return;
    setState(() => n.unread = false);
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _NotificationsHero(
                    total: _items.length,
                    unread: _unreadCount,
                    onMarkAllRead: _unreadCount > 0 ? _markAllRead : null,
                  ),
                ),
                if (_items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      child: const Center(child: _EmptyState()),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final n = _items[index];
                          return _Reveal(
                            index: index,
                            child: _NotificationCard(
                              notif: n,
                              onTap: () => _markRead(n),
                            ),
                          );
                        },
                        childCount: _items.length,
                      ),
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

// ─── HERO ──────────────────────────────────────

class _NotificationsHero extends StatelessWidget {
  final int total;
  final int unread;
  final VoidCallback? onMarkAllRead;

  const _NotificationsHero({
    required this.total,
    required this.unread,
    required this.onMarkAllRead,
  });

  Widget _stripItem(IconData icon, String label, String value) {
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

  Widget _stripDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.15),
      );

  Widget _buildMarkAllButton() {
    final enabled = onMarkAllRead != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onMarkAllRead,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.done_all_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Mark all read',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final read = total - unread;

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
            top: top + 56,
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
            top: top + 112,
            right: 96,
            child: Icon(
              Icons.star_rounded,
              size: 12,
              color: _Tones.amber300.withValues(alpha: 0.9),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AuthHeroChip(
                      icon: Icons.notifications_active_rounded,
                      label: 'UPDATES',
                    ),
                    const Spacer(),
                    _buildMarkAllButton(),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Notifications',
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
                    unread > 0
                        ? 'You have $unread unread ${unread == 1 ? 'update' : 'updates'}'
                        : 'You are all caught up',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AuthColors.emerald950.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      _stripItem(
                        Icons.inbox_rounded,
                        'Total',
                        '$total',
                      ),
                      _stripDivider(),
                      _stripItem(
                        Icons.mark_email_unread_rounded,
                        'Unread',
                        '$unread',
                      ),
                      _stripDivider(),
                      _stripItem(
                        Icons.done_all_rounded,
                        'Read',
                        '$read',
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
}

// ─── NOTIFICATION CARD ─────────────────────────

class _NotificationCard extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;

  const _NotificationCard({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(notif.type);
    final unread = notif.unread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: unread
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tone.bg, tone.bg2],
                  )
                : null,
            color: unread ? null : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread ? tone.border : AppColors.border,
              width: unread ? 1.3 : 1,
            ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: tone.to.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : AppShadows.card,
          ),
          child: Stack(
            children: [
              if (unread)
                Positioned(
                  top: -40,
                  right: -34,
                  child: GlowCircle(
                    size: 120,
                    color: tone.from.withValues(alpha: 0.45),
                  ),
                ),
              if (unread)
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
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: unread ? 1 : 0.8,
                      child: _GradientTile(
                        icon: _iconFor(notif.type),
                        tone: tone,
                        size: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: unread
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: unread
                                        ? AppColors.slate900
                                        : AppColors.slate700,
                                  ),
                                ),
                              ),
                              if (unread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [tone.from, tone.to],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: tone.to.withValues(alpha: 0.45),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notif.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.slate600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: unread
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppColors.slate100,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    unread ? tone.border : AppColors.slate200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: unread ? tone.fg : AppColors.slate400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notif.time,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        unread ? tone.fg : AppColors.slate500,
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
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ───────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tone = _Tones.emerald;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.bg, tone.bg2],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -40,
            child: GlowCircle(
              size: 160,
              color: tone.from.withValues(alpha: 0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GradientTile(
                  icon: Icons.notifications_none_rounded,
                  tone: tone,
                  size: 68,
                ),
                const SizedBox(height: 18),
                Text(
                  'No notifications yet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Updates about your pickups and donations will appear here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.slate600,
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
