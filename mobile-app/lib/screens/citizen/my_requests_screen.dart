// 📁 lib/screens/citizen/my_requests_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'track_driver_screen.dart';

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

// ─── STATUS HELPERS ────────────────────────────

bool _isActiveStatus(String status) =>
    status == 'assigned' || status == 'on_the_way' || status == 'arrived';

_Tone _toneFor(String status) {
  if (_isActiveStatus(status)) return _Tones.blue;
  if (status == 'completed') return _Tones.emerald;
  return _Tones.amber;
}

IconData _iconFor(String status) {
  switch (status) {
    case 'assigned':
      return Icons.local_shipping_rounded;
    case 'on_the_way':
      return Icons.directions_car_rounded;
    case 'arrived':
      return Icons.place_rounded;
    case 'completed':
      return Icons.check_circle_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'assigned':
      return 'ASSIGNED';
    case 'on_the_way':
      return 'ON THE WAY';
    case 'arrived':
      return 'ARRIVED';
    case 'completed':
      return 'COMPLETED';
    default:
      return 'PENDING';
  }
}

String _formatWasteType(String value) {
  switch (value) {
    case 'bones':
      return 'Bones & Skin';
    case 'blood':
      return 'Blood & Fluid';
    case 'other':
      return 'Other';
    default:
      return 'Mixed Waste';
  }
}

class _Counts {
  final int pending;
  final int active;
  final int done;
  const _Counts({
    required this.pending,
    required this.active,
    required this.done,
  });
}

// ─── SCREEN ────────────────────────────────────

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  // The Firestore stream below is already realtime, so pull-to-refresh only
  // gives the user feedback while the listener delivers the latest snapshot.
  Future<void> _onRefresh() =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  Widget _shell(
    BuildContext context, {
    required _Counts? counts,
    required Widget body,
  }) {
    final top = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      edgeOffset: top + 8,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _RequestsHero(counts: counts)),
          body,
        ],
      ),
    );
  }

  Widget _messageBody({
    required IconData icon,
    required String title,
    required String message,
    required _Tone tone,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Center(
          child: _StateCard(
            icon: icon,
            title: title,
            message: message,
            tone: tone,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: Stack(
          children: [
            const Positioned.fill(child: _Backdrop()),
            if (auth.loading)
              _shell(context, counts: null, body: const _LoadingSliver())
            else if (auth.user == null)
              _shell(
                context,
                counts: null,
                body: _messageBody(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in required',
                  message: 'Please sign in to view your requests.',
                  tone: _Tones.blue,
                ),
              )
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('pickupRequests')
                    .where('userId', isEqualTo: auth.user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _shell(
                      context,
                      counts: null,
                      body: _messageBody(
                        icon: Icons.error_outline_rounded,
                        title: 'Something went wrong',
                        message:
                            'Unable to load your requests right now.\n${snapshot.error}',
                        tone: _Tones.rose,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _shell(
                      context,
                      counts: null,
                      body: const _LoadingSliver(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final requests = docs.toList()
                    ..sort((a, b) {
                      final aTime = a.data()['createdAt'];
                      final bTime = b.data()['createdAt'];
                      if (aTime is Timestamp && bTime is Timestamp) {
                        return bTime.compareTo(aTime);
                      }
                      return 0;
                    });

                  int pending = 0, active = 0, done = 0;
                  for (final doc in requests) {
                    final s = (doc.data()['status'] ?? 'pending').toString();
                    if (s == 'completed') {
                      done++;
                    } else if (_isActiveStatus(s)) {
                      active++;
                    } else {
                      pending++;
                    }
                  }
                  final counts =
                      _Counts(pending: pending, active: active, done: done);

                  if (requests.isEmpty) {
                    return _shell(
                      context,
                      counts: counts,
                      body: _messageBody(
                        icon: Icons.inbox_rounded,
                        title: 'No pickup requests yet',
                        message:
                            'Your booked pickups will show up here once you schedule one.',
                        tone: _Tones.emerald,
                      ),
                    );
                  }

                  return _shell(
                    context,
                    counts: counts,
                    body: SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == 0) {
                              return _ListHeader(count: requests.length);
                            }
                            final doc = requests[index - 1];
                            final card = _RequestCard(
                              key: ValueKey(doc.id),
                              docId: doc.id,
                              item: doc.data(),
                            );
                            return index <= 6
                                ? _Reveal(index: index - 1, child: card)
                                : card;
                          },
                          childCount: requests.length + 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─── HERO ──────────────────────────────────────

class _RequestsHero extends StatelessWidget {
  final _Counts? counts;
  const _RequestsHero({required this.counts});

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

  Widget _buildStrip() {
    String v(int? n) => n == null ? '–' : '$n';

    return Container(
      decoration: BoxDecoration(
        color: AuthColors.emerald950.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _stripItem(
            Icons.hourglass_top_rounded,
            'Pending',
            v(counts?.pending),
          ),
          _stripDivider(),
          _stripItem(
            Icons.local_shipping_rounded,
            'Active',
            v(counts?.active),
          ),
          _stripDivider(),
          _stripItem(
            Icons.check_circle_rounded,
            'Completed',
            v(counts?.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canPop) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 4),
                const AuthHeroChip(
                  icon: Icons.receipt_long_rounded,
                  label: 'PICKUP HISTORY',
                ),
                const SizedBox(height: 12),
                Text(
                  'My Requests',
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
                    'Track every pickup you have booked',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LIST HEADER ───────────────────────────────

class _ListHeader extends StatelessWidget {
  final int count;
  const _ListHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final tone = _Tones.emerald;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          _GradientTile(
            icon: Icons.receipt_long_rounded,
            tone: tone,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All Requests',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tone.bg2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.border),
            ),
            child: Text(
              '$count total',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: tone.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REQUEST CARD ──────────────────────────────

class _RequestCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> item;
  const _RequestCard({super.key, required this.docId, required this.item});

  Widget _infoItem(IconData icon, String label, String value, _Tone tone) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: tone.fg.withValues(alpha: 0.8)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.overline.copyWith(
                      color: tone.fg.withValues(alpha: 0.8),
                      fontSize: 10,
                      letterSpacing: 1.0,
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
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = (item['status'] ?? 'pending').toString();
    final String timeSlot = (item['timeSlot'] ?? 'Not set').toString();
    final String location = (item['location'] ?? 'No location').toString();
    final String wasteType = (item['wasteType'] ?? 'mixed').toString();
    final String driverName = (item['driverName'] ?? '').toString();
    final String notes = (item['notes'] ?? '').toString();
    final driverLocation = item['driverLocation'];
    final bool isLive =
        driverLocation is Map && driverLocation['isTracking'] == true;

    final tone = _toneFor(status);
    final emerald = _Tones.emerald;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            color: tone.to.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
            top: -40,
            right: -34,
            child: GlowCircle(
              size: 130,
              color: tone.from.withValues(alpha: 0.45),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + location + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GradientTile(icon: _iconFor(status), tone: tone, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _StatusBadge(label: _statusLabel(status), tone: tone),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Waste type + time slot
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tone.border),
                  ),
                  child: Row(
                    children: [
                      _infoItem(
                        Icons.delete_outline_rounded,
                        'WASTE TYPE',
                        _formatWasteType(wasteType),
                        tone,
                      ),
                      Container(width: 1, height: 34, color: tone.border),
                      _infoItem(
                        Icons.schedule_rounded,
                        'TIME SLOT',
                        timeSlot,
                        tone,
                      ),
                    ],
                  ),
                ),

                // Driver info (if assigned)
                if (driverName.isNotEmpty && status != 'completed') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: emerald.border),
                    ),
                    child: Row(
                      children: [
                        _GradientTile(
                          icon: Icons.person_rounded,
                          tone: emerald,
                          size: 34,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DRIVER',
                                style: AppTextStyles.overline.copyWith(
                                  color: emerald.fg.withValues(alpha: 0.75),
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                driverName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: emerald.fg,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Live tracking indicator
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: emerald.bg2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: emerald.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: emerald.to,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LIVE',
                                  style: AppTextStyles.overline.copyWith(
                                    color: emerald.fg,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Notes
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: tone.fg.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Notes: $notes',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Track Driver button
                if (_isActiveStatus(status)) ...[
                  const SizedBox(height: 14),
                  _PressScale(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackDriverScreen(
                            requestId: docId,
                            requestData: item,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [tone.from, tone.to],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tone.to.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Track Driver',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final _Tone tone;
  const _StatusBadge({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tone.from, tone.to]),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── STATES (empty / error / loading) ──────────

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final _Tone tone;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
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
                _GradientTile(icon: icon, tone: tone, size: 68),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
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

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading your requests…',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
          const _SkeletonCard(),
          const _SkeletonCard(),
          const _SkeletonCard(),
        ]),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.slate200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(160, 14),
                      const SizedBox(height: 8),
                      _bar(70, 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _bar(double.infinity, 48),
          ],
        ),
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
