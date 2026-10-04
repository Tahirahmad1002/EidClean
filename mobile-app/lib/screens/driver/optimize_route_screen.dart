// 📁 lib/screens/driver/optimize_route_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/route_optimizer.dart';
import '../../services/routing_service.dart';
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

class OptimizeRouteScreen extends StatefulWidget {
  const OptimizeRouteScreen({super.key});

  @override
  State<OptimizeRouteScreen> createState() => _OptimizeRouteScreenState();
}

class _OptimizeRouteScreenState extends State<OptimizeRouteScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // ─── STATE ────────────────────────────────────
  bool _loading = true;
  String? _error;
  LatLng? _driverLocation;
  List<OptimizableStop> _stops = [];
  OptimizedRoute? _optimizedRoute;
  RouteResult? _routeLine; // route for the polyline
  bool _accepting = false;

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // ─── MAIN FLOW ────────────────────────────────

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Get driver GPS
      final pos = await _getCurrentPosition();
      if (pos == null) {
        setState(() {
          _error = 'GPS unavailable. Please enable location.';
          _loading = false;
        });
        return;
      }
      _driverLocation = pos;

      // 2. Fetch pending tasks
      final stops = await _fetchPendingStops();
      if (stops.isEmpty) {
        setState(() {
          _error = 'No pending pickups to optimize.';
          _loading = false;
        });
        return;
      }
      _stops = stops;

      // 3. Run optimizer
      final result = await RouteOptimizer.instance.optimize(
        driverLocation: _driverLocation!,
        stops: _stops,
      );
      if (result == null) {
        setState(() {
          _error = 'Could not compute optimized route.';
          _loading = false;
        });
        return;
      }
      _optimizedRoute = result;

      // 4. Fetch full route polyline through the ordered stops
      await _fetchFullRoutePolyline(result);

      setState(() => _loading = false);

      // 5. Fit map to bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapToRoute();
      });
    } catch (e) {
      debugPrint('[OptimizeRoute] error: $e');
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<LatLng?> _getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('[OptimizeRoute] GPS error: $e');
      return null;
    }
  }

  Future<List<OptimizableStop>> _fetchPendingStops() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('pickupRequests')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['assigned', 'arrived']).get();

    final stops = <OptimizableStop>[];
    for (final doc in snap.docs) {
      final stop = OptimizableStop.fromFirestore(
        doc.id,
        doc.data(),
      );
      if (stop != null) stops.add(stop);
    }
    return stops;
  }

  Future<void> _fetchFullRoutePolyline(OptimizedRoute route) async {
    if (_driverLocation == null) return;

    // Build full path: driver → stop1 → stop2 → ...
    final points = <LatLng>[_driverLocation!];
    for (final stop in route.orderedStops) {
      points.add(stop.location);
    }

    // Fetch individual segments and concatenate (OSRM doesn't support
    // multi-leg routes through the Route API easily; Table API only returns
    // distances. For FYP we do segment-by-segment route calls.)
    final segments = <LatLng>[];
    for (var i = 0; i < points.length - 1; i++) {
      try {
        final seg =
            await RoutingService.instance.getRoute(points[i], points[i + 1]);
        if (segments.isEmpty) {
          segments.addAll(seg.polyline);
        } else {
          // Skip first point to avoid duplicate
          segments.addAll(seg.polyline.skip(1));
        }
      } catch (_) {
        // Fallback: straight line
        segments.add(points[i]);
        segments.add(points[i + 1]);
      }
    }

    _routeLine = RouteResult(
      polyline: segments,
      distanceMeters: route.totalDistanceMeters,
      durationSeconds: route.totalDurationSeconds,
      provider: 'osrm-multi-leg',
    );
  }

  // ─── ACCEPT ROUTE ─────────────────────────────

  Future<void> _acceptRoute() async {
    if (_optimizedRoute == null) return;

    setState(() => _accepting = true);

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid;
      if (uid == null) return;

      final taskIds = _optimizedRoute!.orderedTaskIds;

      // 1. Save sequence on driver's doc
      await FirebaseFirestore.instance.collection('drivers').doc(uid).set({
        'optimizedSequence': taskIds,
        'optimizedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Clear the reoptimization flag on completed tasks
      for (final taskId in taskIds) {
        await FirebaseFirestore.instance
            .collection('pickupRequests')
            .doc(taskId)
            .update({
          'routeNeedsReoptimization': false,
        }).catchError((_) {});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Route accepted — follow the sequence'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _accepting = false);
      }
    }
  }

  // ─── MAP HELPERS ──────────────────────────────

  void _fitMapToRoute() {
    if (!_mapReady) return;
    final points = <LatLng>[];
    if (_driverLocation != null) points.add(_driverLocation!);
    for (final stop in _stops) {
      points.add(stop.location);
    }
    if (points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthSystemUi(
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(child: _buildBackdrop()),
        Positioned(
          top: top + 12,
          left: 16,
          child: _lightBackButton(),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _gradientTile(Icons.auto_awesome_rounded, _Tones.amber, size: 64),
              const SizedBox(height: 18),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                'Finding best route...',
                style: AppTextStyles.label.copyWith(
                  color: _Tones.emerald.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lightBackButton() {
    return _PressScale(
      onTap: () => Navigator.pop(context),
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
        child:
            Icon(Icons.arrow_back_rounded, size: 21, color: _Tones.emerald.to),
      ),
    );
  }

  Widget _buildError() {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(child: _buildBackdrop()),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHero(top),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _tintedCardDecoration(_Tones.rose, 24),
                  child: Column(
                    children: [
                      _gradientTile(Icons.error_outline_rounded, _Tones.rose,
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
                        label: 'Try Again',
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
        ),
      ],
    );
  }

  // ─── HERO (error state) ───────────────────────

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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        border: Border.all(color: AuthColors.emerald950.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald950.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 16),
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
              size: 260,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          Positioned(
            top: top + 10,
            right: -24,
            child: Icon(
              Icons.nightlight_round,
              size: 140,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: top + 46,
            right: 74,
            child: Icon(
              Icons.star_rounded,
              size: 11,
              color: _Tones.amber300.withValues(alpha: 0.9),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 22),
            child: Row(
              children: [
                _heroCircleButton(
                  Icons.arrow_back_rounded,
                  () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optimize Route',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'We could not build your route',
                        style: AppTextStyles.caption.copyWith(
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

  // ─── CONTENT ──────────────────────────────────

  Widget _buildContent() {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 5,
          child: _buildMapSection(),
        ),

        // Bottom sheet
        Expanded(
          flex: 6,
          child: _buildSheet(),
        ),
      ],
    );
  }

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
              _sectionHeader(
                'Optimized Sequence',
                'Best order for your pickups',
              ),
              const SizedBox(height: 14),
              _buildSequenceList(),
              const SizedBox(height: 14),
              _buildSummaryCard(),
              const SizedBox(height: 14),
              _buildReasoningCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MAP SECTION ──────────────────────────────

  Widget _buildMapSection() {
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Positioned.fill(child: _buildMap()),

        // Top gradient scrim
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top + 80,
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
              _glassCircleButton(
                Icons.arrow_back_rounded,
                () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              const AuthHeroChip(
                icon: Icons.auto_awesome_rounded,
                label: 'OPTIMIZE ROUTE',
              ),
              const Spacer(),
              _pill(
                '${_stops.length} pickup${_stops.length > 1 ? 's' : ''}',
                _Tones.blue,
                icon: Icons.route_rounded,
              ),
            ],
          ),
        ),

        // Map controls
        Positioned(
          bottom: 26,
          right: 12,
          child: _mapControlBtn(
            icon: Icons.center_focus_strong_rounded,
            onTap: _fitMapToRoute,
          ),
        ),
      ],
    );
  }

  Widget _glassCircleButton(IconData icon, VoidCallback onTap) {
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

  Widget _buildMap() {
    final tone = _Tones.emerald;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation ?? _defaultCenter,
        initialZoom: 13,
        onMapReady: () {
          _mapReady = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapToRoute();
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.eidclean_app',
        ),

        // Full route polyline
        if (_routeLine != null && _routeLine!.polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeLine!.polyline,
                strokeWidth: 5.0,
                color: _Tones.blue.to,
              ),
            ],
          ),

        // Markers
        MarkerLayer(
          markers: [
            // Driver marker
            if (_driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 46,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: tone.to.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
              ),

            // Numbered stop markers
            ..._buildNumberedMarkers(),
          ],
        ),
      ],
    );
  }

  List<Marker> _buildNumberedMarkers() {
    if (_optimizedRoute == null) return [];

    final markers = <Marker>[];
    for (var i = 0; i < _optimizedRoute!.orderedStops.length; i++) {
      final stop = _optimizedRoute!.orderedStops[i];
      final tone = _stopTone(stop.priority);
      markers.add(
        Marker(
          point: stop.location,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tone.from, tone.to],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: tone.to.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  _Tone _stopTone(int priority) {
    switch (priority) {
      case 1:
        return _Tones.rose;
      case 2:
        return _Tones.amber;
      default:
        return _Tones.emerald;
    }
  }

  // ─── SEQUENCE LIST ────────────────────────────

  Widget _buildSequenceList() {
    if (_optimizedRoute == null) return const SizedBox();

    return Column(
      children: [
        _sequenceRow(
          icon: Icons.my_location_rounded,
          tone: _Tones.emerald,
          title: 'Start (Your location)',
          subtitle: 'Current GPS position',
          isLast: false,
        ),
        for (var i = 0; i < _optimizedRoute!.orderedStops.length; i++)
          _sequenceRow(
            icon: Icons.location_on_rounded,
            tone: _stopTone(_optimizedRoute!.orderedStops[i].priority),
            title: _optimizedRoute!.orderedStops[i].rawData['userName'] ??
                'Pickup ${i + 1}',
            subtitle:
                'Stop ${i + 1} • P${_optimizedRoute!.orderedStops[i].priority}',
            isLast: i == _optimizedRoute!.orderedStops.length - 1,
          ),
      ],
    );
  }

  Widget _sequenceRow({
    required IconData icon,
    required _Tone tone,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _gradientTile(icon, tone, size: 34),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [tone.border, AppColors.slate200],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w700,
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

  // ─── SUMMARY CARD ─────────────────────────────

  Widget _buildSummaryCard() {
    if (_optimizedRoute == null) return const SizedBox();

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.42),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _MaskedLattice(alpha: 0.12)),
          Positioned(
            top: -60,
            right: -40,
            child: GlowCircle(
              size: 200,
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryStat(
                    Icons.route_rounded,
                    '${_optimizedRoute!.totalDistanceKm.toStringAsFixed(1)} km',
                    'Total Distance',
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _summaryStat(
                    Icons.timer_rounded,
                    '${_optimizedRoute!.totalDurationMin.toStringAsFixed(0)} min',
                    'Est. Duration',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── REASONING CARD ───────────────────────────

  Widget _buildReasoningCard() {
    if (_optimizedRoute == null) return const SizedBox();
    final tone = _Tones.amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _tintedCardDecoration(tone, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gradientTile(Icons.auto_awesome_rounded, tone, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _optimizedRoute!.reasoning,
              style: AppTextStyles.caption.copyWith(
                color: tone.fg,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ───────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(
            label: 'Recalculate',
            icon: Icons.refresh_rounded,
            tone: _Tones.emerald,
            height: 52,
            onTap: _loading || _accepting ? null : _bootstrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _ToneButton(
            label: _accepting ? 'Saving...' : 'Accept Route',
            icon: Icons.check_circle_rounded,
            tone: _Tones.emerald,
            height: 52,
            loading: _accepting,
            onTap: _accepting ? null : _acceptRoute,
          ),
        ),
      ],
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
          bottom: 160,
          left: -150,
          child: GlowCircle(
            size: 320,
            color: AppColors.accent.withValues(alpha: 0.08),
          ),
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

  Widget _heroCircleButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return _PressScale(
      onTap: onTap ?? () {},
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.16 : 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
          size: 21,
        ),
      ),
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

/// Tone-coloured gradient button with gloss and coloured shadow.
/// A null [onTap] renders the disabled state.
class _ToneButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _Tone tone;
  final VoidCallback? onTap;
  final double height;
  final bool loading;

  const _ToneButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.height = 48,
    this.loading = false,
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
    final enabled = widget.onTap != null;

    return Opacity(
      opacity: enabled || widget.loading ? 1 : 0.55,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
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
                      if (widget.loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      else
                        Icon(widget.icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 14.5,
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
      ),
    );
  }
}

/// White button with a tone-coloured outline (secondary action).
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final _Tone tone;
  final VoidCallback? onTap;
  final double height;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: _PressScale(
        onTap: onTap ?? () {},
        child: Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, tone.bg],
            ),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: tone.to, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: tone.to.withValues(alpha: 0.14),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: tone.to),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(
                    color: tone.fg,
                    fontSize: 14,
                  ),
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
