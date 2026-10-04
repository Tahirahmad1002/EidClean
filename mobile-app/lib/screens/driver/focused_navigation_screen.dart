// 📁 lib/screens/driver/focused_navigation_screen.dart
//
// Google Maps-style navigation with:
//   Preview   — DIRECTIONS + START buttons
//   Active    — fullscreen map, follows driver, "I've Arrived" button
//   Arrival   — confirmation dialog before proceeding

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../services/routing_service.dart';
import '../../services/location_service.dart';
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

class FocusedNavigationScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const FocusedNavigationScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<FocusedNavigationScreen> createState() =>
      _FocusedNavigationScreenState();
}

class _FocusedNavigationScreenState extends State<FocusedNavigationScreen> {
  // ─── MAP ──────────────────────────────────────
  final MapController _mapController = MapController();
  bool _mapReady = false;

  // ─── STATE ────────────────────────────────────
  bool _isNavigating = false;
  bool _arrivalConfirmed = false; // Set true only after confirmation

  // ─── LOCATIONS ────────────────────────────────
  LatLng? _pickupLocation;
  LatLng? _driverLocation;

  // ─── ROUTE ────────────────────────────────────
  RouteResult? _route;
  bool _loadingRoute = false;
  LatLng? _lastRouteFrom;
  static const double _routeRefreshMeters = 100.0;

  // ─── ARRIVAL ──────────────────────────────────
  bool _isClose = false;
  double? _distanceToPickupMeters;
  static const double _closeThresholdMeters = 30.0; // banner shows
  static const double _arrivalThresholdMeters = 15.0; // auto-confirm hint

  // ─── GPS ──────────────────────────────────────
  bool _loadingGps = true;
  DateTime _lastUpdate = DateTime.now();

  // ─── SUBSCRIPTIONS ────────────────────────────
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<DocumentSnapshot>? _driverDocSub;
  Timer? _ticker;

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _loadPickupLocation();
    _startGpsTracking();
    _listenToDriverDoc();
    _startTicker();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _driverDocSub?.cancel();
    _ticker?.cancel();
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
      debugPrint('[FocusedNav] Pickup load error: $e');
    }
  }

  // ─── GPS TRACKING ─────────────────────────────

  Future<void> _startGpsTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingGps = false);
        return;
      }

      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _driverLocation = LatLng(initial.latitude, initial.longitude);
          _loadingGps = false;
        });
        _updateArrivalStatus();
        _fetchRoute();
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        final newLoc = LatLng(pos.latitude, pos.longitude);

        setState(() {
          _driverLocation = newLoc;
          _lastUpdate = DateTime.now();
        });

        // Auto-follow only when actively navigating
        if (_isNavigating && _mapReady) {
          _mapController.move(newLoc, _mapController.camera.zoom);
        }

        _updateArrivalStatus();
        _fetchRoute();
      });
    } catch (e) {
      debugPrint('[FocusedNav] GPS error: $e');
      if (mounted) setState(() => _loadingGps = false);
    }
  }

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

      // Fallback source if device GPS hasn't fired
      if (_driverLocation == null) {
        final loc = DriverLocation.fromFirestore(data['currentLocation']);
        if (loc != null) {
          setState(() => _driverLocation = loc.latLng);
          _updateArrivalStatus();
          _fetchRoute();
        }
      }
    });
  }

  // ─── ARRIVAL DETECTION ────────────────────────

  void _updateArrivalStatus() {
    if (_driverLocation == null || _pickupLocation == null) {
      setState(() => _distanceToPickupMeters = null);
      return;
    }
    final meters = Geolocator.distanceBetween(
      _driverLocation!.latitude,
      _driverLocation!.longitude,
      _pickupLocation!.latitude,
      _pickupLocation!.longitude,
    );
    setState(() {
      _distanceToPickupMeters = meters;
      _isClose = meters <= _closeThresholdMeters;
    });
  }

  // ─── ROUTE ────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;

    if (_lastRouteFrom != null && _route != null) {
      final drift = Geolocator.distanceBetween(
        _lastRouteFrom!.latitude,
        _lastRouteFrom!.longitude,
        _driverLocation!.latitude,
        _driverLocation!.longitude,
      );
      if (drift < _routeRefreshMeters) return;
    }

    setState(() => _loadingRoute = true);

    try {
      final result = await RoutingService.instance.getRoute(
        _driverLocation!,
        _pickupLocation!,
      );
      if (mounted) {
        setState(() {
          _route = result;
          _lastRouteFrom = _driverLocation;
          _loadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('[FocusedNav] Route error: $e');
      if (mounted) setState(() => _loadingRoute = false);
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // ─── ACTIONS ──────────────────────────────────

  /// Open in Google Maps (external app) — for the DIRECTIONS button.
  Future<void> _openExternalDirections() async {
    if (_pickupLocation == null) return;
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${_pickupLocation!.latitude},${_pickupLocation!.longitude}&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open Google Maps', isError: true);
    }
  }

  /// Fit the map to the full route (used in preview + as in-app "directions").
  void _fitToRoute() {
    if (!_mapReady) return;
    final points = <LatLng>[];
    if (_driverLocation != null) points.add(_driverLocation!);
    if (_pickupLocation != null) points.add(_pickupLocation!);
    if (points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  Future<void> _startNavigation() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;

    // Start GPS broadcasting to Firestore
    final ok = await LocationService.instance.startTracking(
      driverId: uid,
      taskId: widget.taskId,
    );

    if (!ok) {
      _showSnack('Location permission required', isError: true);
      return;
    }

    // Update task status to on_the_way
    try {
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': 'on_the_way',
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FocusedNav] Status update error: $e');
    }

    if (mounted) {
      setState(() => _isNavigating = true);
      // Recenter at tighter zoom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_driverLocation != null && _mapReady) {
          _mapController.move(_driverLocation!, 18);
        }
      });
    }
  }

  Future<void> _stopNavigation() async {
    await LocationService.instance.stopTracking();
    if (mounted) setState(() => _isNavigating = false);
  }

  /// Handle back press — confirm if navigating, then stop tracking.
  Future<void> _handleBack() async {
    // If actively navigating, ask for confirmation
    if (_isNavigating) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => const _ConfirmDialog(
          icon: Icons.warning_amber_rounded,
          toneKey: _DialogTone.amber,
          title: 'Exit Navigation?',
          message:
              'The task will remain "In Progress" — you can continue it later from the dashboard.',
          cancelLabel: 'Stay',
          confirmLabel: 'Exit',
          confirmDanger: true,
        ),
      );
      if (shouldExit != true) return;
    }

    // Stop GPS tracking before leaving
    await LocationService.instance.stopTracking();

    if (mounted) Navigator.pop(context);
  }

  Future<void> _callCustomer() async {
    final phone = widget.taskData['userPhone'] ?? '';
    if (phone.isEmpty) {
      _showSnack('Phone not available', isError: true);
      return;
    }
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  /// Confirm-then-arrive flow. Prevents accidental completion.
  Future<void> _confirmAndArrive() async {
    // First confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        icon: Icons.location_on_rounded,
        toneKey: _DialogTone.emerald,
        title: 'Confirm Arrival',
        message: _isClose
            ? 'You are at the pickup location. Confirm to continue to photo capture.'
            : 'You appear to be ${_distanceToPickupMeters?.toStringAsFixed(0) ?? "?"} m away. '
                'Are you sure you have arrived?',
        cancelLabel: 'Not Yet',
        confirmLabel: 'Yes, Arrived',
        confirmDanger: false,
      ),
    );

    if (confirmed != true) return;

    // Perform arrival
    setState(() => _arrivalConfirmed = true);

    await LocationService.instance.stopTracking();

    try {
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': 'arrived',
        'arrivedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FocusedNav] Arrival update error: $e');
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletePickup(
          taskId: widget.taskId,
          taskData: widget.taskData,
          distanceKm: _route?.distanceKm,
          etaText: _etaText,
        ),
      ),
    );
  }

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

  void _recenterToDriver() {
    if (_driverLocation != null && _mapReady) {
      _mapController.move(_driverLocation!, _isNavigating ? 18 : 16);
    }
  }

  // ─── GETTERS ──────────────────────────────────

  String get _etaText {
    if (_route == null) return '—';
    final min = _route!.durationMinutes;
    if (min < 1) return '< 1 min';
    return '${min.toStringAsFixed(0)} min';
  }

  String get _distanceText {
    if (_distanceToPickupMeters != null) {
      final m = _distanceToPickupMeters!;
      if (m < 100) return '${m.toStringAsFixed(0)} m';
      return '${(m / 1000).toStringAsFixed(1)} km';
    }
    if (_route == null) return '—';
    return '${_route!.distanceKm.toStringAsFixed(1)} km';
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate900,
      body: AuthSystemUi(
        child: Stack(
          children: [
            _buildMap(),

            // Top scrim for readability of floating controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top + 90,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AuthColors.emerald950.withValues(alpha: 0.5),
                        AuthColors.emerald950.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(child: _buildTopBar()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isNavigating
                    ? _buildActiveMiniBar()
                    : _buildPreviewBottomSheet(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAP ──────────────────────────────────────

  Widget _buildMap() {
    final initialZoom = _isNavigating ? 18.0 : 15.0;
    final tone = _Tones.emerald;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation ?? _pickupLocation ?? _defaultCenter,
        initialZoom: initialZoom,
        onMapReady: () {
          _mapReady = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isNavigating) {
              _recenterToDriver();
            } else {
              _fitToRoute();
            }
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
                strokeWidth: 6.0,
                color: _route!.isFallback ? AppColors.slate400 : _Tones.blue.to,
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            if (_pickupLocation != null)
              Marker(
                point: _pickupLocation!,
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
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tone.from, tone.to],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: tone.to.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── TOP BAR ──────────────────────────────────

  Widget _buildTopBar() {
    if (_isNavigating) {
      final tone = _Tones.blue;

      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _roundIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: _handleBack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, tone.bg],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tone.border, width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: tone.to.withValues(alpha: 0.25),
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
                      _distanceText,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tone.fg,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 18, color: tone.border),
                    const SizedBox(width: 10),
                    Icon(Icons.timer_rounded, color: _Tones.amber.to, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _etaText,
                      style: AppTextStyles.titleLarge.copyWith(
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
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Preview top bar
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          _roundIconButton(
            icon: Icons.my_location_rounded,
            onTap: _recenterToDriver,
          ),
          const SizedBox(width: 8),
          _roundIconButton(
            icon: Icons.center_focus_strong_rounded,
            onTap: _fitToRoute,
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _Tones.emerald.border),
          boxShadow: [
            BoxShadow(
              color: _Tones.emerald.to.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: _Tones.emerald.to, size: 22),
      ),
    );
  }

  // ─── SHEET DECORATION ─────────────────────────

  BoxDecoration _sheetDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF0FDF4)],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      border: Border(
        top: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.9)),
      ),
      boxShadow: [
        BoxShadow(
          color: AuthColors.emerald900.withValues(alpha: 0.22),
          blurRadius: 30,
          offset: const Offset(0, -10),
        ),
      ],
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.slate300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  // ─── PREVIEW BOTTOM SHEET ─────────────────────

  Widget _buildPreviewBottomSheet() {
    final userName = widget.taskData['userName'] ?? 'Customer';
    final userPhone = widget.taskData['userPhone'] ?? '';
    final location = widget.taskData['location'] ?? 'Pickup location';
    final tone = _Tones.emerald;

    return Container(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: _sheetDecoration(),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 14),

            // Route summary
            _buildSummaryCard(),
            const SizedBox(height: 14),

            // Customer info
            Row(
              children: [
                _gradientTile(Icons.person_rounded, tone, size: 46),
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
                      if (userPhone.isNotEmpty)
                        Text(
                          userPhone,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (userPhone.isNotEmpty)
                  _PressScale(
                    onTap: _callCustomer,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [tone.from, tone.to],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tone.to.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Location
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Tones.rose.bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Tones.rose.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: _Tones.rose.to, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // GPS status
            _pill(
              _loadingGps ? 'Getting GPS...' : 'GPS ready',
              _loadingGps ? _Tones.amber : _Tones.emerald,
              icon: _loadingGps
                  ? Icons.gps_not_fixed_rounded
                  : Icons.gps_fixed_rounded,
            ),
            const SizedBox(height: 16),

            // DIRECTIONS + START
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    label: 'DIRECTIONS',
                    icon: Icons.directions_rounded,
                    tone: _Tones.blue,
                    height: 58,
                    onTap: _openExternalDirections,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _ToneButton(
                    label: 'START',
                    icon: Icons.play_arrow_rounded,
                    tone: _Tones.blue,
                    height: 58,
                    onTap: _loadingGps ? null : _startNavigation,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
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
                  _summaryStat(Icons.route_rounded, _distanceText, 'Distance'),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _summaryStat(Icons.timer_rounded, _etaText, 'ETA'),
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
              fontSize: 20,
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

  // ─── ACTIVE MINI BAR ──────────────────────────

  Widget _buildActiveMiniBar() {
    final tone = _Tones.emerald;

    return Container(
      key: const ValueKey('active'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: _sheetDecoration(),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),

            // Arrival hint banner (never auto-completes)
            if (_isClose) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: _tintedCardDecoration(tone, 18),
                child: Row(
                  children: [
                    _gradientTile(Icons.check_circle_rounded, tone, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You're close — tap below when you arrive",
                        style: AppTextStyles.label.copyWith(
                          color: tone.fg,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Live status
            Row(
              children: [
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
                const SizedBox(width: 8),
                Text(
                  'Navigating',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tone.fg,
                  ),
                ),
                const Spacer(),
                _pill(_distanceText, _Tones.blue, icon: Icons.route_rounded),
              ],
            ),
            const SizedBox(height: 12),

            // Arrived button — always same text, requires confirmation
            _ToneButton(
              label: "I've Arrived at Location",
              icon: Icons.location_on_rounded,
              tone: _Tones.emerald,
              height: 56,
              onTap: _arrivalConfirmed ? null : _confirmAndArrive,
            ),

            const SizedBox(height: 10),

            // Recenter / Stop row
            Row(
              children: [
                Expanded(
                  child: _OutlineButton(
                    label: 'Recenter',
                    icon: Icons.my_location_rounded,
                    tone: _Tones.emerald,
                    height: 44,
                    onTap: _recenterToDriver,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineButton(
                    label: 'Stop',
                    icon: Icons.stop_circle_rounded,
                    tone: _Tones.rose,
                    height: 44,
                    onTap: _stopNavigation,
                  ),
                ),
              ],
            ),
          ],
        ),
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
}

// ─── CONFIRM DIALOG ──────────────────────────────────────────────────

enum _DialogTone { emerald, amber }

class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final _DialogTone toneKey;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool confirmDanger;

  const _ConfirmDialog({
    required this.icon,
    required this.toneKey,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmDanger,
  });

  @override
  Widget build(BuildContext context) {
    final tone = toneKey == _DialogTone.amber ? _Tones.amber : _Tones.emerald;
    final confirmTone = confirmDanger ? _Tones.rose : _Tones.emerald;

    return Dialog(
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
          border: Border.all(color: tone.border),
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
                _gradientTile(icon, tone, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
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
              message,
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
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _Tones.slate.bg2,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: _Tones.slate.border),
                      ),
                      child: Text(
                        cancelLabel,
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
                  flex: 2,
                  child: _ToneButton(
                    label: confirmLabel,
                    icon: confirmDanger
                        ? Icons.logout_rounded
                        : Icons.check_circle_rounded,
                    tone: confirmTone,
                    onTap: () => Navigator.pop(context, true),
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
