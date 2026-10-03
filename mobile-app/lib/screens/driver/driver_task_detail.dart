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
import 'complete_pickup.dart';

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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text(
          'Navigation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh route',
            onPressed: _loadingRoute ? null : _refreshRoute,
            icon: const Icon(Icons.refresh),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _distanceKm != null
                  ? '${_distanceKm!.toStringAsFixed(1)} km'
                  : '...',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── MAP WITH ROUTE ─────────────
            _buildMap(),
            const SizedBox(height: 12),

            // ─── ROUTE INFO BANNER ───────────
            _buildRouteBanner(),
            const SizedBox(height: 16),

            // ─── START/STOP TRIP BUTTON ──────
            _buildTripButton(),
            const SizedBox(height: 16),

            // ─── LIVE STATUS ─────────────────
            if (_isTripActive) _buildLiveStatusBanner(),
            if (_isTripActive) const SizedBox(height: 16),

            // ─── NAVIGATE + CALL ─────────────
            _buildActionRow(),
            const SizedBox(height: 20),

            // ─── PICKUP CARD ─────────────────
            _buildPickupCard(
              userName: userName,
              userPhone: userPhone,
              location: location,
              animals: animals,
              wasteType: wasteType,
              timeSlot: timeSlot,
            ),
            const SizedBox(height: 20),

            // ─── ARRIVED BUTTON ──────────────
            _buildArrivedButton(),

            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAP WIDGET ───────────────────────────────

  Widget _buildMap() {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.eidclean_app',
                ),

                // Blue route polyline
                if (_route != null && _route!.polyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route!.polyline,
                        strokeWidth: 5.0,
                        color: _route!.isFallback
                            ? const Color(0xFF9CA3AF) // grey if fallback
                            : const Color(0xFF2563EB), // blue if real
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
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFEF4444),
                          size: 42,
                        ),
                      ),
                    if (_driverLocation != null)
                      Marker(
                        point: _driverLocation!,
                        width: 46,
                        height: 46,
                        child: Transform.rotate(
                          angle: ((_route != null && _route!.polyline.length > 1)
                                  ? 0
                                  : 0) *
                              3.14159 /
                              180,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
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
                    icon: Icons.my_location,
                    onTap: _centerOnDriver,
                  ),
                  const SizedBox(height: 8),
                  _mapControlBtn(
                    icon: Icons.center_focus_strong,
                    onTap: _fitBothMarkers,
                  ),
                ],
              ),
            ),

            // Route loading overlay
            if (_loadingRoute)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF10B981),
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: const Color(0xFF10B981)),
        ),
      ),
    );
  }

  // ─── ROUTE BANNER ─────────────────────────────

  Widget _buildRouteBanner() {
    if (_routeError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber,
                color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _routeError!,
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFallback
            ? const Color(0xFFF3F4F6)
            : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFallback
              ? const Color(0xFFD1D5DB)
              : const Color(0xFF2563EB).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFallback ? Icons.route_outlined : Icons.route,
            color: isFallback
                ? const Color(0xFF6B7280)
                : const Color(0xFF2563EB),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallback
                      ? 'Approximate route (offline)'
                      : 'Road route ready',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFallback
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  '$_distanceText • ETA $_etaText',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFallback
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1E40AF),
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _loadingGps
            ? null
            : (_isTripActive ? _stopTrip : _startTrip),
        icon: Icon(
          _isTripActive ? Icons.stop_circle : Icons.play_circle,
          size: 22,
        ),
        label: Text(
          _loadingGps
              ? 'Getting GPS...'
              : (_isTripActive ? 'Stop Trip' : 'Start Trip (Go Live)'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTripActive
              ? const Color(0xFFEF4444)
              : const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ─── LIVE STATUS BANNER ───────────────────────

  Widget _buildLiveStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Broadcasting live location to citizen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const Icon(Icons.wifi_tethering,
              color: Color(0xFF10B981), size: 18),
        ],
      ),
    );
  }

  // ─── NAVIGATE + CALL ──────────────────────────

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _refreshRoute,
              icon: const Icon(Icons.navigation, size: 20),
              label: const Text(
                'Refresh Route',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 50,
          width: 60,
          child: ElevatedButton(
            onPressed: _callCustomer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Icon(Icons.phone, size: 22),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          if (userPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  userPhone,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.pets, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '$animals Animal${animals > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _getWasteChips(wasteType),
                ),
              ),
            ],
          ),
          if (timeSlot.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  timeSlot,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── ARRIVED BUTTON ───────────────────────────

  Widget _buildArrivedButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
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
        icon: const Icon(Icons.location_on),
        label: const Text(
          "I've Arrived at Location",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
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
    final colors = {
      'skin': const Color(0xFFF59E0B),
      'bones': const Color(0xFF3B82F6),
      'offal': const Color(0xFFEF4444),
    };
    final bgColors = {
      'skin': const Color(0xFFFEF3C7),
      'bones': const Color(0xFFE0E7FF),
      'offal': const Color(0xFFFCE4EC),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[type] ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colors[type] ?? Colors.grey[700],
        ),
      ),
    );
  }
}