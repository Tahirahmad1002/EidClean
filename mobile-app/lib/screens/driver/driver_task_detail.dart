// 📁 lib/screens/driver/driver_task_detail.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../models/driver_location.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'complete_pickup.dart';

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

class DriverTaskDetail extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const DriverTaskDetail({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<DriverTaskDetail> createState() => _DriverTaskDetailState();
}

class _DriverTaskDetailState extends State<DriverTaskDetail> {
  // ─── MAP ──────────────────────────────────────
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // ─── LOCATIONS ────────────────────────────────
  LatLng? _pickupLocation;
  LatLng? _driverLocation;

  // ─── ROUTE ────────────────────────────────────
  RouteResult? _route;
  bool _loadingRoute = false;
  String? _routeError;

  // ─── STATE ────────────────────────────────────
  String _status = 'assigned';
  bool _isTripActive = false;
  bool _loadingGps = true;
  StreamSubscription<DocumentSnapshot>? _driverDocSub;

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _status = widget.taskData['status'] ?? 'assigned';
    _loadPickupLocation();
    _loadInitialDriverPosition();
    _listenToDriverDoc();
  }

  @override
  void dispose() {
    _driverDocSub?.cancel();
    // Note: We do NOT stop LocationService here — the trip
    // keeps broadcasting until the driver explicitly stops.
    super.dispose();
  }

  // ─── LOAD PICKUP LOCATION ─────────────────────

  void _loadPickupLocation() {
    try {
      final lat = widget.taskData['latitude'];
      final lng = widget.taskData['longitude'];

      if (lat != null && lng != null) {
        _pickupLocation = LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        );
      } else if (widget.taskData['geoPoint'] != null) {
        final geo = widget.taskData['geoPoint'] as GeoPoint;
        _pickupLocation = LatLng(geo.latitude, geo.longitude);
      }
    } catch (e) {
      debugPrint('[DriverTaskDetail] Pickup load error: $e');
    }
  }

  // ─── INITIAL GPS ──────────────────────────────

  Future<void> _loadInitialDriverPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _driverLocation = LatLng(position.latitude, position.longitude);

        // Fetch route once we have both points
        if (_pickupLocation != null) {
          _fetchRoute();
        }
      }
    } catch (e) {
      debugPrint('[DriverTaskDetail] Initial GPS error: $e');
    }

    if (mounted) {
      setState(() => _loadingGps = false);

      if (_mapReady && _pickupLocation != null) {
        _mapController.move(_pickupLocation!, 14);
      }
    }
  }

  // ─── LISTEN TO DRIVER'S OWN DOC ───────────────

  void _listenToDriverDoc() {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    _driverDocSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      final loc = DriverLocation.fromFirestore(data['currentLocation']);
      if (loc == null) return;

      setState(() {
        _driverLocation = loc.latLng;
      });

      // Follow the driver's own position
      if (_mapReady && _isTripActive) {
        _mapController.move(loc.latLng, 16);
      }
    });
  }

  // ─── FETCH ROUTE FROM OSRM ────────────────────

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      final result = await RoutingService.instance.getRoute(
        _driverLocation!,
        _pickupLocation!,
      );
      if (mounted) {
        setState(() {
          _route = result;
          _loadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeError = 'Route unavailable';
          _loadingRoute = false;
        });
      }
    }
  }

  // ─── START TRIP (REAL GPS) ────────────────────

  Future<void> _startTrip() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) {
      _showSnack('Not signed in', isError: true);
      return;
    }

    // 1. Start real GPS streaming
    final ok = await LocationService.instance.startTracking(
      driverId: uid,
      taskId: widget.taskId,
    );

    if (!ok) {
      _showSnack('Location permission required', isError: true);
      return;
    }

    // 2. Update task status
    await _updateStatus('on_the_way');

    if (mounted) {
      setState(() => _isTripActive = true);
      _showSnack('Trip started — broadcasting live location');
    }
  }

  // ─── STOP TRIP ────────────────────────────────

  Future<void> _stopTrip() async {
    await LocationService.instance.stopTracking();
    await _updateStatus('assigned');

    if (mounted) {
      setState(() => _isTripActive = false);
    }
  }

  // ─── REFRESH ROUTE ────────────────────────────

  Future<void> _refreshRoute() async {
    if (_driverLocation == null) {
      // Try to get current GPS first
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        setState(() {
          _driverLocation = LatLng(pos.latitude, pos.longitude);
        });
      } catch (_) {}
    }
    await _fetchRoute();
  }

  // ─── STATUS UPDATE ────────────────────────────

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _status = newStatus);
    } catch (e) {
      debugPrint('[DriverTaskDetail] Status update error: $e');
    }
  }

  // ─── CALL CUSTOMER ────────────────────────────

  Future<void> _callCustomer() async {
    final phone = widget.taskData['userPhone'] ?? '';
    if (phone.isEmpty) {
      _showSnack('Customer phone not available', isError: true);
      return;
    }
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // ─── SNAP TO DRIVER ───────────────────────────

  void _centerOnDriver() {
    if (_driverLocation != null && _mapReady) {
      _mapController.move(_driverLocation!, 16);
    }
  }

  // ─── SNAP TO FIT BOTH ─────────────────────────

  void _fitBothMarkers() {
    if (_driverLocation == null || _pickupLocation == null || !_mapReady) {
      return;
    }
    final bounds = LatLngBounds.fromPoints([
      _driverLocation!,
      _pickupLocation!,
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
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

  double? get _distanceKm => _route?.distanceKm;

  String get _etaText {
    if (_route == null) return '—';
    final min = _route!.durationMinutes;
    if (min < 1) return '< 1 min';
    return '${min.toStringAsFixed(0)} min';
  }

  String get _distanceText {
    if (_distanceKm == null) return 'Calculating...';
    if (_distanceKm! < 0.1) return 'Less than 100m';
    return '${_distanceKm!.toStringAsFixed(1)} km away';
  }

  _Tone get _statusTone {
    switch (_status) {
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

  String get _statusLabel {
    switch (_status) {
      case 'on_the_way':
        return 'On the way';
      case 'arrived':
        return 'Arrived';
      case 'completed':
        return 'Completed';
      default:
        return 'Assigned';
    }
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = widget.taskData;
    final location = data['location'] ?? 'No location';
    final userName = data['userName'] ?? 'Customer';
    final userPhone = data['userPhone'] ?? '';
    final animals = data['animals'] ?? 1;
    final wasteType = data['wasteType'] ?? 'mixed';
    final timeSlot = data['timeSlot'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuthSystemUi(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackdrop()),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── MAP WITH ROUTE ─────────────
                        _Reveal(index: 0, child: _buildMap()),
                        const SizedBox(height: 12),

                        // ─── ROUTE INFO BANNER ───────────
                        _buildRouteBanner(),
                        if (_route != null || _routeError != null)
                          const SizedBox(height: 16),

                        // ─── START/STOP TRIP BUTTON ──────
                        _Reveal(index: 1, child: _buildTripButton()),
                        const SizedBox(height: 16),

                        // ─── LIVE STATUS ─────────────────
                        if (_isTripActive) ...[
                          _buildLiveStatusBanner(),
                          const SizedBox(height: 16),
                        ],

                        // ─── NAVIGATE + CALL ─────────────
                        _Reveal(index: 2, child: _buildActionRow()),
                        const SizedBox(height: 22),

                        // ─── PICKUP CARD ─────────────────
                        _Reveal(
                          index: 3,
                          child: _buildPickupCard(
                            userName: userName,
                            userPhone: userPhone,
                            location: location,
                            animals: animals,
                            wasteType: wasteType,
                            timeSlot: timeSlot,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ─── ARRIVED BUTTON ──────────────
                        _Reveal(index: 4, child: _buildArrivedButton()),

                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.slate600,
                            ),
                            child: Text(
                              'Back to Dashboard',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate600,
                              ),
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

  // ─── HERO ─────────────────────────────────────

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
            bottom: -100,
            left: 30,
            child: GlowCircle(
              size: 240,
              color: const Color(0xFF5EEAD4).withValues(alpha: 0.20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _heroCircleButton(
                      Icons.arrow_back_rounded,
                      () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navigation',
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Head to the pickup location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color:
                                  AuthColors.emerald200.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _heroCircleButton(
                      Icons.refresh_rounded,
                      _loadingRoute ? null : _refreshRoute,
                      tooltip: 'Refresh route',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AuthHeroChip(
                      icon: Icons.straighten_rounded,
                      label: _distanceKm != null
                          ? '${_distanceKm!.toStringAsFixed(1)} KM'
                          : '... KM',
                    ),
                    AuthHeroChip(
                      icon: Icons.schedule_rounded,
                      label: 'ETA ${_etaText.toUpperCase()}',
                    ),
                    AuthHeroChip(
                      icon: Icons.flag_rounded,
                      label: _statusLabel.toUpperCase(),
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

  Widget _heroCircleButton(
    IconData icon,
    VoidCallback? onTap, {
    String? tooltip,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
      ),
    );
  }

  // ─── MAP WIDGET ───────────────────────────────

  Widget _buildMap() {
    final tone = _Tones.emerald;

    return Container(
      width: double.infinity,
      height: 320,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.from, tone.to],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: tone.to.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
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
                    if (_pickupLocation != null)
                      Marker(
                        point: _pickupLocation!,
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: _Tones.rose.to,
                          size: 42,
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
                        width: 46,
                        height: 46,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: AppColors.primaryDark,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Map control buttons
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

            // Route loading overlay
            if (_loadingRoute)
              Container(
                color: AuthColors.emerald950.withValues(alpha: 0.18),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
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

  // ─── ROUTE BANNER ─────────────────────────────

  Widget _buildRouteBanner() {
    if (_routeError != null) {
      final tone = _Tones.amber;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _tintedCardDecoration(tone, 20),
        child: Row(
          children: [
            _gradientTile(Icons.warning_amber_rounded, tone, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _routeError!,
                style: AppTextStyles.label.copyWith(
                  color: tone.fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_route == null) {
      return const SizedBox.shrink();
    }

    final isFallback = _route!.isFallback;
    final tone = isFallback ? _Tones.slate : _Tones.blue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tintedCardDecoration(tone, 20),
      child: Row(
        children: [
          _gradientTile(
            isFallback ? Icons.route_outlined : Icons.route_rounded,
            tone,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallback
                      ? 'Approximate route (offline)'
                      : 'Road route ready',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone.fg,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$_distanceText • ETA $_etaText',
                  style: AppTextStyles.caption.copyWith(
                    color: tone.fg.withValues(alpha: 0.85),
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

  // ─── TRIP BUTTON ──────────────────────────────

  Widget _buildTripButton() {
    return _ToneButton(
      label: _loadingGps
          ? 'Getting GPS...'
          : (_isTripActive ? 'Stop Trip' : 'Start Trip (Go Live)'),
      icon:
          _isTripActive ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
      tone: _isTripActive ? _Tones.rose : _Tones.blue,
      height: 54,
      onTap: _loadingGps ? null : (_isTripActive ? _stopTrip : _startTrip),
    );
  }

  // ─── LIVE STATUS BANNER ───────────────────────

  Widget _buildLiveStatusBanner() {
    final tone = _Tones.emerald;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(12),
      decoration: _tintedCardDecoration(tone, 20),
      child: Row(
        children: [
          _gradientTile(Icons.wifi_tethering_rounded, tone, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live now',
                  style: AppTextStyles.caption.copyWith(
                    color: tone.fg.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Broadcasting live location to citizen',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone.fg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: tone.from,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: tone.from.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NAVIGATE + CALL ──────────────────────────

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _ToneButton(
            label: 'Refresh Route',
            icon: Icons.navigation_rounded,
            tone: _Tones.indigo,
            height: 50,
            onTap: _refreshRoute,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: _ToneButton(
            label: '',
            icon: Icons.phone_rounded,
            tone: _Tones.emerald,
            height: 50,
            iconOnly: true,
            onTap: _callCustomer,
          ),
        ),
      ],
    );
  }

  // ─── PICKUP CARD ──────────────────────────────

  Widget _buildPickupCard({
    required String userName,
    required String userPhone,
    required String location,
    required int animals,
    required String wasteType,
    required String timeSlot,
  }) {
    final tone = _statusTone;

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
            bottom: -22,
            child: Icon(
              Icons.local_shipping_rounded,
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
                    Text(
                      'PICKUP DETAILS',
                      style: AppTextStyles.overline.copyWith(
                        color: tone.fg.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tone.to,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: tone.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _gradientTile(Icons.person_rounded, tone, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 13,
                                  color: tone.to,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  userPhone,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.slate600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tone.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, size: 18, color: tone.to),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.slate700,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    if (timeSlot.isNotEmpty)
                      _pill(
                        timeSlot,
                        _Tones.emerald,
                        icon: Icons.schedule_rounded,
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

  // ─── ARRIVED BUTTON ───────────────────────────

  Widget _buildArrivedButton() {
    return _ToneButton(
      label: "I've Arrived at Location",
      icon: Icons.location_on_rounded,
      tone: _Tones.emerald,
      height: 56,
      onTap: () async {
        // Stop tracking when arrived
        if (_isTripActive) {
          await LocationService.instance.stopTracking();
        }
        await _updateStatus('arrived');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CompletePickup(
                taskId: widget.taskId,
                taskData: widget.taskData,
                distanceKm: _distanceKm,
                etaText: _etaText,
              ),
            ),
          );
        }
      },
    );
  }

  // ─── WASTE CHIPS ──────────────────────────────

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

  // ─── SHARED HELPERS ───────────────────────────

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
  final bool iconOnly;

  const _ToneButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    this.height = 48,
    this.iconOnly = false,
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
      opacity: enabled ? 1 : 0.55,
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
                      Icon(widget.icon, size: 20, color: Colors.white),
                      if (!widget.iconOnly) ...[
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
