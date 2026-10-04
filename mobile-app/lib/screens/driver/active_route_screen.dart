// 📁 lib/screens/driver/active_route_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/routing_service.dart';
import '../../services/route_optimizer.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'focused_navigation_screen.dart';
import 'driver_home.dart';

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

// ─── SCREEN ──────────────────────────────────────────────────────────

class ActiveRouteScreen extends StatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  State<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends State<ActiveRouteScreen> {
  // ─── MAP ──────────────────────────────────────
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // ─── STATE ────────────────────────────────────
  bool _loading = true;
  String? _error;

  /// All active stops in the current optimized sequence (in order).
  List<OptimizableStop> _sequence = [];

  /// Total completed tasks (today) — used for progress + empty state.
  int _completedCount = 0;

  /// Earliest started time for session duration display.
  DateTime? _sessionStartTime;

  /// Only the currently active (first) stop.
  OptimizableStop? get _activeStop =>
      _sequence.isEmpty ? null : _sequence.first;

  /// All pending stops after the active one.
  List<OptimizableStop> get _lockedStops =>
      _sequence.length <= 1 ? [] : _sequence.sublist(1);

  /// Driver's live position.
  LatLng? _driverLocation;

  /// Route for the ACTIVE leg only (driver → active stop).
  RouteResult? _activeRoute;
  bool _loadingRoute = false;

  // ─── SUBSCRIPTIONS ────────────────────────────
  StreamSubscription<DocumentSnapshot>? _driverSub;
  StreamSubscription<QuerySnapshot>? _tasksSub;

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _tasksSub?.cancel();
    super.dispose();
  }

  // ─── BOOTSTRAP ────────────────────────────────

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      setState(() {
        _error = 'Not signed in';
        _loading = false;
      });
      return;
    }

    // 1. Get initial GPS position
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _driverLocation = LatLng(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('[ActiveRoute] GPS error: $e');
    }

    // 2. Attach Firestore listeners
    _listenToDriverDoc(uid);
    _listenToPendingTasks(uid);

    setState(() => _loading = false);
  }

  // ─── DRIVER DOC LISTENER (GPS) ────────────────

  void _listenToDriverDoc(String uid) {
    _driverSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final loc = data['currentLocation'];
      if (loc is Map && loc['latitude'] != null && loc['longitude'] != null) {
        final newLat = (loc['latitude'] as num).toDouble();
        final newLng = (loc['longitude'] as num).toDouble();

        setState(() {
          _driverLocation = LatLng(newLat, newLng);
        });

        // Auto-follow on map
        if (_mapReady && _statusIsActive) {
          _mapController.move(_driverLocation!, 16);
        }

        // Refetch route if moved > 100m
        _maybeRefreshRoute();
      }
    });
  }

  // ─── TASKS LISTENER (SEQUENCE + STATUS) ───────

  void _listenToPendingTasks(String uid) {
    _tasksSub = FirebaseFirestore.instance
        .collection('pickupRequests')
        .where('driverId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final stops = <OptimizableStop>[];
      int completed = 0;
      DateTime? earliestStart;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString();

        if (status == 'completed') {
          completed++;
          final startedAt = data['startedAt'];
          if (startedAt is Timestamp) {
            final dt = startedAt.toDate();
            if (earliestStart == null || dt.isBefore(earliestStart)) {
              earliestStart = dt;
            }
          }
        } else if (status == 'assigned' ||
            status == 'arrived' ||
            status == 'on_the_way') {
          final stop = OptimizableStop.fromFirestore(doc.id, data);
          if (stop != null) stops.add(stop);
        }
      }

      setState(() {
        _completedCount = completed;
        _sessionStartTime = earliestStart;
      });

      // Reorder by the driver's optimizedSequence if present
      _applyOptimizedOrder(stops);
    });
  }

  Future<void> _applyOptimizedOrder(List<OptimizableStop> stops) async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    // Read the saved sequence from driver doc
    List<String>? orderedIds;
    try {
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();
      final seq = driverDoc.data()?['optimizedSequence'];
      if (seq is List) {
        orderedIds = seq.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    // Reorder
    List<OptimizableStop> ordered = stops;
    if (orderedIds != null && orderedIds.isNotEmpty) {
      final map = {for (var s in stops) s.taskId: s};
      ordered = <OptimizableStop>[];
      for (final id in orderedIds) {
        if (map.containsKey(id)) ordered.add(map[id]!);
      }
      // Append any stops not in sequence (edge case)
      for (final s in stops) {
        if (!orderedIds.contains(s.taskId)) ordered.add(s);
      }
    }

    if (!mounted) return;

    setState(() {
      _sequence = ordered;
    });

    // Fetch route for the active leg
    _refreshActiveRoute();

    // Fit map to active + driver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToActiveLeg();
    });
  }

  bool get _statusIsActive => _sequence.isNotEmpty;

  // ─── ROUTE HANDLING ───────────────────────────

  LatLng? _lastRouteFrom;

  Future<void> _refreshActiveRoute() async {
    final active = _activeStop;
    if (active == null || _driverLocation == null) {
      if (mounted) setState(() => _activeRoute = null);
      return;
    }

    setState(() => _loadingRoute = true);

    try {
      final result = await RoutingService.instance.getRoute(
        _driverLocation!,
        active.location,
      );
      if (!mounted) return;
      setState(() {
        _activeRoute = result;
        _lastRouteFrom = _driverLocation;
        _loadingRoute = false;
      });
    } catch (e) {
      debugPrint('[ActiveRoute] Route error: $e');
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  void _maybeRefreshRoute() {
    if (_driverLocation == null) return;
    if (_activeStop == null) return;

    if (_lastRouteFrom == null) {
      _refreshActiveRoute();
      return;
    }

    final drift = Geolocator.distanceBetween(
      _lastRouteFrom!.latitude,
      _lastRouteFrom!.longitude,
      _driverLocation!.latitude,
      _driverLocation!.longitude,
    );

    if (drift >= 100) {
      _refreshActiveRoute();
    }
  }

  // ─── MAP CONTROLS ─────────────────────────────

  void _fitToActiveLeg() {
    if (!_mapReady) return;
    final active = _activeStop;
    if (_driverLocation == null || active == null) return;

    final bounds = LatLngBounds.fromPoints([
      _driverLocation!,
      active.location,
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _centerOnDriver() {
    if (_driverLocation != null && _mapReady) {
      _mapController.move(_driverLocation!, 16);
    }
  }

  // ─── SAFE EXIT (fixes white screen) ───────────

  void _safeExit() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverHome()),
      );
    }
  }

  // ─── ACTIONS ──────────────────────────────────

  void _openFocusedNavigation() {
    final active = _activeStop;
    if (active == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusedNavigationScreen(
          taskId: active.taskId,
          taskData: active.rawData,
        ),
      ),
    );
  }

  // ─── SESSION DURATION ─────────────────────────

  String get _sessionDurationLabel {
    if (_sessionStartTime == null) return '—';
    final diff = DateTime.now().difference(_sessionStartTime!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}h ${m}m';
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AuthSystemUi(
          child: Stack(
            children: [
              Positioned.fill(child: _buildBackdrop()),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _gradientTile(Icons.route_rounded, _Tones.emerald,
                        size: 64),
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(
                        color: AppColors.primary),
                    const SizedBox(height: 14),
                    Text(
                      'Loading your route...',
                      style: AppTextStyles.label.copyWith(
                        color: _Tones.emerald.fg,
                        fontWeight: FontWeight.w700,
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

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AuthSystemUi(
          child: Stack(
            children: [
              Positioned.fill(child: _buildBackdrop()),
              Column(
                children: [
                  _buildSimpleHero(
                    chipIcon: Icons.route_rounded,
                    chipLabel: 'ACTIVE ROUTE',
                    title: 'Something went wrong',
                    subtitle: 'We could not load your route',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: _tintedCardDecoration(_Tones.rose, 24),
                      child: Column(
                        children: [
                          _gradientTile(
                              Icons.error_outline_rounded, _Tones.rose,
                              size: 56),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: _Tones.rose.fg,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ToneButton(
                            label: 'Retry',
                            icon: Icons.refresh_rounded,
                            tone: _Tones.rose,
                            onTap: _bootstrap,
                          ),
                        ],
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

    if (_sequence.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthSystemUi(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: _buildMapSection(),
            ),
            Expanded(
              flex: 6,
              child: _buildSheet(),
            ),
          ],
        ),
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

  // ─── SIMPLE HERO (error / empty) ──────────────

  Widget _buildSimpleHero({
    required IconData chipIcon,
    required String chipLabel,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
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
              size: 280,
              color: AppColors.accent.withValues(alpha: 0.48),
            ),
          ),
          Positioned(
            bottom: -110,
            left: 40,
            child: GlowCircle(
              size: 260,
              color: const Color(0xFF5EEAD4).withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: top + 30,
            right: -30,
            child: Icon(
              Icons.nightlight_round,
              size: 170,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: top + 36,
            right: 34,
            child: Transform.rotate(
              angle: 0.32,
              child: Icon(
                Icons.nightlight_round,
                size: 44,
                color: _Tones.amber200.withValues(alpha: 0.92),
                shadows: [
                  Shadow(
                    color: _Tones.amber300.withValues(alpha: 0.65),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AuthHeroChip(icon: chipIcon, label: chipLabel),
                    const Spacer(),
                    if (trailing != null) trailing,
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(right: 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.body.copyWith(
                          color: AuthColors.emerald200.withValues(alpha: 0.9),
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

  // ─── EMPTY / SHIFT COMPLETE STATE ─────────────

  Widget _buildEmptyState() {
    final tone = _Tones.emerald;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthSystemUi(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSimpleHero(
                    chipIcon: Icons.emoji_events_rounded,
                    chipLabel: 'SHIFT COMPLETE',
                    title: 'Shift Complete!',
                    subtitle: 'Eid Mubarak — great work today',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      children: [
                        _Reveal(
                          index: 0,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [tone.from, tone.to],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tone.to.withValues(alpha: 0.45),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "You've completed all your pickups for today.",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.slate600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _Reveal(
                          index: 1,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 18,
                            ),
                            decoration: _tintedCardDecoration(tone, 24),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _statItem(
                                    icon: Icons.local_shipping_rounded,
                                    label: 'Completed',
                                    value: '$_completedCount',
                                    tone: _Tones.emerald,
                                  ),
                                  Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    color: tone.border,
                                  ),
                                  _statItem(
                                    icon: Icons.access_time_rounded,
                                    label: 'Duration',
                                    value: _sessionDurationLabel,
                                    tone: _Tones.indigo,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _Reveal(
                          index: 2,
                          child: _ToneButton(
                            label: 'Back to Dashboard',
                            icon: Icons.dashboard_rounded,
                            tone: _Tones.emerald,
                            height: 54,
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DriverHome(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required _Tone tone,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _gradientTile(icon, tone, size: 38),
          const SizedBox(height: 8),
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

  // ─── MAP SECTION ──────────────────────────────

  Widget _buildMapSection() {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(child: _buildMap()),

        // Top gradient scrim for readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + 90,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AuthColors.emerald950.withValues(alpha: 0.55),
                    AuthColors.emerald950.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating header
        Positioned(
          top: top + 10,
          left: 14,
          right: 14,
          child: Row(
            children: [
              _heroCircleButton(Icons.arrow_back_rounded, _safeExit),
              const SizedBox(width: 10),
              const AuthHeroChip(
                icon: Icons.route_rounded,
                label: 'ACTIVE ROUTE',
              ),
              const Spacer(),
              _ExitPill(onTap: _safeExit),
            ],
          ),
        ),

        // Route info chip
        if (_activeRoute != null)
          Positioned(
            top: top + 62,
            left: 14,
            right: 14,
            child: _buildRouteInfoCard(),
          ),

        // Map controls
        Positioned(
          bottom: 26,
          right: 12,
          child: Column(
            children: [
              _mapControlBtn(
                icon: Icons.my_location_rounded,
                onTap: _centerOnDriver,
              ),
              const SizedBox(height: 8),
              _mapControlBtn(
                icon: Icons.center_focus_strong_rounded,
                onTap: _fitToActiveLeg,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroCircleButton(IconData icon, VoidCallback onTap) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AuthColors.emerald900.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    final tone = _Tones.blue;
    final route = _activeRoute!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, tone.bg],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _gradientTile(Icons.route_rounded, tone, size: 32),
          const SizedBox(width: 10),
          Text(
            '${route.distanceKm.toStringAsFixed(1)} km',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: tone.fg,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 16, color: tone.border),
          const SizedBox(width: 10),
          Icon(Icons.timer_rounded, color: _Tones.amber.to, size: 18),
          const SizedBox(width: 4),
          Text(
            '${route.durationMinutes.toStringAsFixed(0)} min',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: _Tones.amber.fg,
            ),
          ),
          const Spacer(),
          if (_loadingRoute)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (route.isFallback)
            Icon(Icons.cloud_off_rounded, size: 16, color: _Tones.slate.to),
        ],
      ),
    );
  }

  // ─── MAP WIDGET ───────────────────────────────

  Widget _buildMap() {
    final active = _activeStop;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation ?? active?.location ?? _defaultCenter,
        initialZoom: 15,
        onMapReady: () {
          _mapReady = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitToActiveLeg();
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.eidclean_app',
        ),
        if (_activeRoute != null && _activeRoute!.polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _activeRoute!.polyline,
                strokeWidth: 5.0,
                color: _activeRoute!.isFallback
                    ? AppColors.slate400
                    : _Tones.blue.to,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (active != null)
              Marker(
                point: active.location,
                width: 56,
                height: 56,
                child: Icon(
                  Icons.location_on_rounded,
                  color: _Tones.rose.to,
                  size: 48,
                  shadows: [
                    Shadow(
                      color: _Tones.rose.to.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            if (_driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 52,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primaryDark,
                    size: 26,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _mapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _Tones.emerald.border),
          boxShadow: [
            BoxShadow(
              color: _Tones.emerald.to.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _Tones.emerald.to),
      ),
    );
  }

  // ─── BOTTOM SHEET ─────────────────────────────

  Widget _buildSheet() {
    const radius = BorderRadius.vertical(top: Radius.circular(30));

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
            color: AuthColors.emerald900.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.xl + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildProgressHeader(),
              const SizedBox(height: 16),
              _buildActiveCard(),
              if (_lockedStops.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildLockedSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROGRESS HEADER ──────────────────────────

  Widget _buildProgressHeader() {
    final total = _sequence.length + _completedCount;
    final current = _completedCount + 1;
    final progress = total == 0 ? 0.0 : current / total;
    final tone = _Tones.emerald;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _tintedCardDecoration(tone, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AuthColors.emerald400, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Pickup $current of $total',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tone.border),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.white),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tone.from, tone.to],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: tone.to.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIVE CARD ──────────────────────────────

  Widget _buildActiveCard() {
    final active = _activeStop;
    if (active == null) return const SizedBox();

    final data = active.rawData;
    final userName = data['userName'] ?? 'Customer';
    final userPhone = data['userPhone'] ?? '';
    final location = data['location'] ?? 'No location';
    final animals = data['animals'] ?? 1;
    final wasteType = (data['wasteType'] ?? 'mixed').toString();
    final timeSlot = data['timeSlot'] ?? '';

    return Container(
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
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            bottom: -26,
            right: 40,
            child: Icon(
              Icons.nightlight_round,
              size: 110,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                            'ACTIVE',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (timeSlot.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              timeSlot.toString().split(' ').first,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _cardInfoRow(Icons.location_on_rounded, '$location',
                    maxLines: 2),
                if (userPhone.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _cardInfoRow(Icons.phone_rounded, '$userPhone'),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _glassPill(
                      '$animals Animal${animals > 1 ? 's' : ''}',
                      Icons.pets_rounded,
                    ),
                    _glassPill(wasteType, Icons.recycling_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                _GoldButton(
                  label: 'Start Navigation',
                  icon: Icons.navigation_rounded,
                  onTap: _openFocusedNavigation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon,
              color: Colors.white.withValues(alpha: 0.85), size: 14),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCKED SECTION ───────────────────────────

  Widget _buildLockedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                  'Upcoming (${_lockedStops.length})',
                  style:
                      AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                ),
                Text('Unlocks after the active pickup',
                    style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._lockedStops.asMap().entries.map((entry) {
          final idx = entry.key + 2;
          final stop = entry.value;
          return _buildLockedCard(idx, stop);
        }),
      ],
    );
  }

  Widget _buildLockedCard(int position, OptimizableStop stop) {
    final data = stop.rawData;
    final userName = data['userName'] ?? 'Customer';
    final location = data['location'] ?? 'No location';
    final tone = _Tones.slate;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _tintedCardDecoration(tone, 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tone.from, tone.to],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: tone.to.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              '$position',
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: tone.border),
            ),
            child: Icon(Icons.lock_rounded, size: 15, color: tone.to),
          ),
        ],
      ),
    );
  }

  // ─── SHARED HELPERS ───────────────────────────

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

/// Small glass "Exit" pill for the floating map header.
class _ExitPill extends StatelessWidget {
  final VoidCallback onTap;
  const _ExitPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AuthColors.emerald900.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Exit',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold gradient CTA used on the emerald active card.
class _GoldButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GoldButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<_GoldButton> {
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
        child: Container(
          height: 50,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCD34D), AppColors.accent],
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent
                    .withValues(alpha: _pressed ? 0.3 : 0.55),
                blurRadius: _pressed ? 10 : 18,
                offset: Offset(0, _pressed ? 3 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 18, color: AuthColors.emerald950),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  color: AuthColors.emerald950,
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
        scale: _pressed ? 0.94 : 1,
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