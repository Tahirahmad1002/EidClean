// lib/screens/citizen/track_driver_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/driver_location.dart';
import '../../services/routing_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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

  static final _Tone slate = _Tone(
    bg: const Color(0xFFF8FAFC),
    bg2: const Color(0xFFF1F5F9),
    border: const Color(0xFFE2E8F0),
    from: const Color(0xFF94A3B8),
    to: const Color(0xFF475569),
    fg: const Color(0xFF334155),
  );
}

class _StatusInfo {
  final IconData icon;
  final _Tone tone;
  final String label;
  final String shortLabel;
  final String description;

  const _StatusInfo({
    required this.icon,
    required this.tone,
    required this.label,
    required this.shortLabel,
    required this.description,
  });
}

// ─── SCREEN ──────────────────────────────────────────────────────────

class TrackDriverScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const TrackDriverScreen({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<TrackDriverScreen> createState() => _TrackDriverScreenState();
}

class _TrackDriverScreenState extends State<TrackDriverScreen> {
  // ─── MAP ──────────────────────────────────────
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // ─── DATA ─────────────────────────────────────
  LatLng? _pickupLocation;
  DriverLocation? _driverLoc;
  String _driverId = '';
  String _driverName = '';
  String _driverPhone = '';
  String _status = 'assigned';

  // ─── ROUTE ────────────────────────────────────
  RouteResult? _route;
  bool _loadingRoute = false;
  LatLng? _lastRouteFrom; // to detect movement
  static const double _routeRefreshMeters = 100.0;

  // ─── TICKER ───────────────────────────────────
  Timer? _ticker;
  DateTime _lastUpdate = DateTime.now();

  // ─── SUBSCRIPTIONS ────────────────────────────
  StreamSubscription<DocumentSnapshot>? _requestSub;
  StreamSubscription<DocumentSnapshot>? _driverSub;

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _loadPickupLocation();
    _listenToRequest();
    _startTicker();
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _driverSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  // ─── LOAD PICKUP LOCATION ─────────────────────

  void _loadPickupLocation() {
    try {
      final lat = widget.requestData['latitude'];
      final lng = widget.requestData['longitude'];

      if (lat != null && lng != null) {
        _pickupLocation = LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );
      } else if (widget.requestData['geoPoint'] != null) {
        final geo = widget.requestData['geoPoint'] as GeoPoint;
        _pickupLocation = LatLng(geo.latitude, geo.longitude);
      }
    } catch (e) {
      debugPrint('[TrackDriver] Pickup load error: $e');
    }
  }

  // ─── LISTEN TO REQUEST DOC ────────────────────

  void _listenToRequest() {
    debugPrint(
        '[TrackDriver] Starting request listener on ${widget.requestId}');

    _requestSub = FirebaseFirestore.instance
        .collection('pickupRequests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) {
        debugPrint('[TrackDriver] Snapshot missing or unmounted');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final newDriverId = (data['driverId'] ?? '').toString();

      debugPrint(
          '[TrackDriver] Request snapshot: driverId=$newDriverId, status=${data['status']}');

      setState(() {
        _status = data['status'] ?? 'assigned';
        _driverName = data['driverName'] ?? '';
        _driverPhone = data['driverPhone'] ?? data['userPhone'] ?? '';
      });

      // Attach driver listener if driverId changed
      if (newDriverId.isNotEmpty && newDriverId != _driverId) {
        debugPrint('[TrackDriver] Attaching driver listener for $newDriverId');
        _driverId = newDriverId;
        _listenToDriver();
      }
    });
  }

  // ─── LISTEN TO DRIVER'S LOCATION DOC ──────────

  void _listenToDriver() {
    _driverSub?.cancel();
    if (_driverId.isEmpty) return;

    debugPrint('[TrackDriver] Listening to drivers/$_driverId');

    _driverSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(_driverId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('[TrackDriver] Driver snapshot: exists=${snapshot.exists}');
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      final loc = DriverLocation.fromFirestore(data['currentLocation']);
      debugPrint(
          '[TrackDriver] Parsed location: ${loc?.latitude}, ${loc?.longitude}');

      if (loc == null) {
        debugPrint('[TrackDriver] currentLocation null or malformed');
        return;
      }

      final previousLoc = _driverLoc;

      setState(() {
        _driverLoc = loc;
        _lastUpdate = DateTime.now();
      });

      // Auto-follow driver (only when on_the_way)
      if (_mapReady && _status == 'on_the_way') {
        _mapController.move(loc.latLng, 15);
      }

      // Refetch route if driver moved significantly
      final from = previousLoc?.latLng;
      if (from != null && _pickupLocation != null) {
        final moved = Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          loc.latitude,
          loc.longitude,
        );
        if (moved >= _routeRefreshMeters) {
          _fetchRoute();
        }
      } else if (_route == null) {
        // First time getting driver location — fetch route
        _fetchRoute();
      }
    });
  }

  // ─── FETCH ROUTE FROM OSRM ────────────────────

  Future<void> _fetchRoute() async {
    if (_driverLoc == null || _pickupLocation == null) return;

    // Skip if we already have a fresh route from a nearly identical start
    if (_lastRouteFrom != null && _route != null) {
      final drift = Geolocator.distanceBetween(
        _lastRouteFrom!.latitude,
        _lastRouteFrom!.longitude,
        _driverLoc!.latitude,
        _driverLoc!.longitude,
      );
      if (drift < _routeRefreshMeters) return;
    }

    setState(() => _loadingRoute = true);

    try {
      final result = await RoutingService.instance.getRoute(
        _driverLoc!.latLng,
        _pickupLocation!,
      );
      if (mounted) {
        setState(() {
          _route = result;
          _lastRouteFrom = _driverLoc!.latLng;
          _loadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('[TrackDriver] Route fetch error: $e');
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  // ─── TICKER (for "Xs ago" text) ───────────────

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // ─── CALL DRIVER ──────────────────────────────

  Future<void> _callDriver() async {
    if (_driverPhone.isEmpty) {
      _showSnack('Driver phone not available', isError: true);
      return;
    }
    try {
      final uri = Uri.parse('tel:$_driverPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Could not open the dialer', isError: true);
      }
    } catch (e) {
      debugPrint('[TrackDriver] Call error: $e');
      _showSnack('Could not place the call', isError: true);
    }
  }

  // ─── MAP CONTROLS ─────────────────────────────

  void _centerOnDriver() {
    if (_driverLoc != null && _mapReady) {
      _mapController.move(_driverLoc!.latLng, 16);
    }
  }

  void _fitBothMarkers() {
    if (!_mapReady) return;
    final points = <LatLng>[];
    if (_driverLoc != null) points.add(_driverLoc!.latLng);
    if (_pickupLocation != null) points.add(_pickupLocation!);
    if (points.length < 2) {
      if (points.length == 1) _mapController.move(points.first, 15);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // ─── SNACKBAR ─────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── GETTERS ──────────────────────────────────

  String get _distanceText {
    if (_route == null) return '—';
    final km = _route!.distanceKm;
    if (km < 0.1) return '< 100m';
    return '${km.toStringAsFixed(1)} km';
  }

  String get _etaText {
    if (_route == null) return '—';
    final min = _route!.durationMinutes;
    if (min < 1) return '< 1 min';
    return '${min.toStringAsFixed(0)} min';
  }

  String get _lastUpdateText {
    final secs = DateTime.now().difference(_lastUpdate).inSeconds;
    if (secs < 5) return 'Just now';
    if (secs < 60) return '${secs}s ago';
    final mins = secs ~/ 60;
    return '${mins}m ago';
  }

  bool get _isStale => DateTime.now().difference(_lastUpdate).inSeconds > 60;

  _StatusInfo get _statusInfo {
    switch (_status) {
      case 'assigned':
        return _StatusInfo(
          icon: Icons.check_circle_rounded,
          tone: _Tones.blue,
          label: 'Driver Assigned',
          shortLabel: 'Assigned',
          description: 'Preparing to start the trip',
        );
      case 'on_the_way':
        return _StatusInfo(
          icon: Icons.local_shipping_rounded,
          tone: _Tones.amber,
          label: 'On The Way',
          shortLabel: 'On the way',
          description: 'Heading to your location',
        );
      case 'arrived':
        return _StatusInfo(
          icon: Icons.location_on_rounded,
          tone: _Tones.emerald,
          label: 'Driver Arrived',
          shortLabel: 'Arrived',
          description: 'Driver is at your location',
        );
      case 'completed':
        return _StatusInfo(
          icon: Icons.verified_rounded,
          tone: _Tones.emerald,
          label: 'Completed',
          shortLabel: 'Completed',
          description: 'Pickup completed successfully',
        );
      default:
        return _StatusInfo(
          icon: Icons.hourglass_top_rounded,
          tone: _Tones.slate,
          label: 'Pending',
          shortLabel: 'Pending',
          description: 'Waiting for driver assignment',
        );
    }
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo;

    return AuthSystemUi(
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHero(info),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Reveal(index: 0, child: _buildMapCard()),
                        const SizedBox(height: 20),
                        _Reveal(index: 1, child: _buildStatusCard(info)),
                        if (_driverName.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Reveal(index: 2, child: _buildDriverCard()),
                        ],
                        if (_driverLoc != null) ...[
                          const SizedBox(height: 16),
                          _Reveal(index: 3, child: _buildDistanceEtaRow()),
                        ] else ...[
                          const SizedBox(height: 16),
                          _Reveal(index: 3, child: _buildWaitingCard()),
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

  // ─── BACKDROP ─────────────────────────────────

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

  // ─── HERO ─────────────────────────────────────

  Widget _buildHero(_StatusInfo info) {
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
                  icon: Icons.sensors_rounded,
                  label: 'LIVE TRACKING',
                ),
                const SizedBox(height: 12),
                Text(
                  'Track Driver',
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
                    'Follow your pickup in real time',
                    style: AppTextStyles.body.copyWith(
                      color: AuthColors.emerald200.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _buildHeroStrip(info),
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

  Widget _buildHeroStrip(_StatusInfo info) {
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
          item(info.icon, 'Status', info.shortLabel),
          divider(),
          item(
            Icons.update_rounded,
            'Updated',
            _driverLoc == null ? '—' : _lastUpdateText,
          ),
          divider(),
          item(
            Icons.person_rounded,
            'Driver',
            _driverName.isEmpty ? 'Pending' : _driverName.split(' ').first,
          ),
        ],
      ),
    );
  }

  // ─── MAP CARD ─────────────────────────────────

  Widget _buildMapCard() {
    return Container(
      height: 340,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.slate200,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _Tones.emerald.border, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AuthColors.emerald900.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickupLocation ?? _defaultCenter,
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBothMarkers();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eidclean_app',
              ),

              // Route polyline
              if (_route != null && _route!.polyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.polyline,
                      strokeWidth: 5.0,
                      color: _route!.isFallback
                          ? AppColors.slate400
                          : _Tones.blue.to,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Pickup marker
                  if (_pickupLocation != null)
                    Marker(
                      point: _pickupLocation!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on,
                        color: _Tones.rose.to,
                        size: 42,
                        shadows: [
                          Shadow(
                            color: _Tones.rose.to.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),

                  // Driver marker (rotated by heading)
                  if (_driverLoc != null)
                    Marker(
                      point: _driverLoc!.latLng,
                      width: 52,
                      height: 52,
                      child: Transform.rotate(
                        angle:
                            ((_driverLoc!.heading ?? 0) * 3.14159265) / 180.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AuthColors.emerald900
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Live / stale chip
          if (_driverLoc != null && _status == 'on_the_way')
            Positioned(top: 12, left: 12, child: _buildLiveChip()),

          // Route loading indicator
          if (_loadingRoute)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _Tones.emerald.border),
                  boxShadow: [
                    BoxShadow(
                      color: AuthColors.emerald900.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updating route...',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _Tones.emerald.fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Map controls
          Positioned(
            bottom: 12,
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
                  onTap: _fitBothMarkers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChip() {
    final stale = _isStale;
    final tone = stale ? _Tones.amber : _Tones.emerald;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.border),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!stale)
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: tone.to,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tone.from.withValues(alpha: 0.7),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
          else
            Icon(Icons.wifi_off_rounded, size: 14, color: tone.to),
          const SizedBox(width: 7),
          Text(
            stale ? 'Signal lost' : 'Live',
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: tone.fg,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _lastUpdateText,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.slate500,
            ),
          ),
        ],
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
              color: AuthColors.emerald900.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }

  // ─── STATUS CARD ──────────────────────────────

  Widget _buildStatusCard(_StatusInfo info) {
    final tone = info.tone;

    return Container(
      width: double.infinity,
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
              info.icon,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _gradientTile(info.icon, tone, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.description,
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
          ),
        ],
      ),
    );
  }

  // ─── DRIVER CARD ──────────────────────────────

  Widget _buildDriverCard() {
    final tone = _Tones.emerald;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: _tintedCardDecoration(tone, 24),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: GlowCircle(
              size: 140,
              color: tone.from.withValues(alpha: 0.35),
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
                    _gradientTile(Icons.badge_rounded, tone, size: 30),
                    const SizedBox(width: 8),
                    Text(
                      'Driver Details',
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tone.fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _gradientTile(Icons.person_rounded, tone, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          if (_driverPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _driverPhone,
                              style: AppTextStyles.caption.copyWith(
                                color: tone.fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CallButton(onTap: _callDriver),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DISTANCE / ETA ───────────────────────────

  Widget _buildDistanceEtaRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statCard(
              'Distance',
              _distanceText,
              Icons.route_rounded,
              _Tones.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              'ETA',
              _etaText,
              Icons.timer_rounded,
              _Tones.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, _Tone tone) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
      decoration: _tintedCardDecoration(tone, 22),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -44,
            child: GlowCircle(
              size: 110,
              color: tone.from.withValues(alpha: 0.45),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _gradientTile(icon, tone, size: 38),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.stat.copyWith(
                    fontSize: 26,
                    color: tone.fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tone.fg.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── WAITING CARD ─────────────────────────────

  Widget _buildWaitingCard() {
    final tone = _Tones.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _tintedCardDecoration(tone, 24),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: tone.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: CircularProgressIndicator(
                color: tone.to,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _status == 'assigned'
                ? 'Waiting for driver to start the trip...'
                : 'Locating driver...',
            style: AppTextStyles.body.copyWith(
              color: tone.fg,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── SHARED PIECES ────────────────────────────

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

class _CallButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CallButton({required this.onTap});

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
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
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 48,
          height: 48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.primaryDark],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: AuthColors.emerald400
                    .withValues(alpha: _pressed ? 0.25 : 0.50),
                blurRadius: _pressed ? 8 : 18,
                offset: Offset(0, _pressed ? 2 : 8),
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
              const Icon(Icons.phone_rounded, size: 22, color: Colors.white),
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
