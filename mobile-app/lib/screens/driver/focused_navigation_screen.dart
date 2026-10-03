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
import 'complete_pickup.dart';

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
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Exit Navigation?'),
          ],
        ),
        content: const Text(
          'The task will remain "In Progress" — you can continue it later from the dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Exit'),
          ),
        ],
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
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Confirm Arrival'),
          ],
        ),
        content: Text(
          _isClose
              ? 'You are at the pickup location. Confirm to continue to photo capture.'
              : 'You appear to be ${_distanceToPickupMeters?.toStringAsFixed(0) ?? "?"} m away. '
                  'Are you sure you have arrived?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Yes, Arrived'),
          ),
        ],
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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMap(),
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
    );
  }

  // ─── MAP ──────────────────────────────────────

  Widget _buildMap() {
    final initialZoom = _isNavigating ? 18.0 : 15.0;

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
                color: _route!.isFallback
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF2563EB),
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
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFEF4444),
                  size: 48,
                ),
              ),
            if (_driverLocation != null)
              Marker(
                point: _driverLocation!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
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
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _roundIconButton(
              icon: Icons.arrow_back,
              onTap: _handleBack,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route,
                        color: Color(0xFF2563EB), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _distanceText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 18, color: Colors.grey[300]),
                    const SizedBox(width: 12),
                    const Icon(Icons.timer,
                        color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _etaText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_loadingRoute)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
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
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          _roundIconButton(
            icon: Icons.my_location,
            onTap: _recenterToDriver,
          ),
          const SizedBox(width: 8),
          _roundIconButton(
            icon: Icons.center_focus_strong,
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: const Color(0xFF111827), size: 22),
        ),
      ),
    );
  }

  // ─── PREVIEW BOTTOM SHEET ─────────────────────

  Widget _buildPreviewBottomSheet() {
    final userName = widget.taskData['userName'] ?? 'Customer';
    final userPhone = widget.taskData['userPhone'] ?? '';
    final location = widget.taskData['location'] ?? 'Pickup location';

    return Container(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.route,
                            color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          _distanceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const Text(
                          'Distance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(Icons.timer,
                            color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          _etaText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const Text(
                          'ETA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Customer info
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (userPhone.isNotEmpty)
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (userPhone.isNotEmpty)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _callCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.phone, size: 20),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Location
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFEF4444), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // GPS status
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _loadingGps
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _loadingGps ? 'Getting GPS...' : 'GPS ready',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🆕 TWO BUTTONS: DIRECTIONS + START
            Row(
              children: [
                // DIRECTIONS button (secondary)
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: _openExternalDirections,
                      icon: const Icon(Icons.directions, size: 22),
                      label: const Text(
                        'DIRECTIONS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // START button (primary)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _loadingGps ? null : _startNavigation,
                      icon: const Icon(Icons.play_arrow, size: 26),
                      label: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor:
                            const Color(0xFF2563EB).withOpacity(0.5),
                      ),
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

  // ─── ACTIVE MINI BAR ──────────────────────────

  Widget _buildActiveMiniBar() {
    return Container(
      key: const ValueKey('active'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arrival hint banner (never auto-completes)
            if (_isClose) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF10B981), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You're close — tap below when you arrive",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Navigating',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                Text(
                  _distanceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Arrived button — always same text, requires confirmation
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _arrivalConfirmed ? null : _confirmAndArrive,
                icon: const Icon(Icons.location_on, size: 22),
                label: const Text(
                  "I've Arrived at Location",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Recenter / Stop row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recenterToDriver,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Recenter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stopNavigation,
                    icon: const Icon(Icons.stop_circle, size: 16),
                    label: const Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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