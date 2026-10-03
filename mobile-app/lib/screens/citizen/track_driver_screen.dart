// 📁 lib/screens/citizen/track_driver_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/driver_location.dart';
import '../../services/routing_service.dart';

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
    debugPrint('[TrackDriver] 🔄 Starting request listener on ${widget.requestId}');

    _requestSub = FirebaseFirestore.instance
        .collection('pickupRequests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) {
        debugPrint('[TrackDriver] ⚠️ Snapshot missing or unmounted');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final newDriverId = (data['driverId'] ?? '').toString();

      debugPrint('[TrackDriver] 📩 Request snapshot: driverId=$newDriverId, status=${data['status']}');

      setState(() {
        _status = data['status'] ?? 'assigned';
        _driverName = data['driverName'] ?? '';
        _driverPhone = data['driverPhone'] ?? data['userPhone'] ?? '';
      });

      // Attach driver listener if driverId changed
      if (newDriverId.isNotEmpty && newDriverId != _driverId) {
        debugPrint('[TrackDriver] 🚀 Attaching driver listener for $newDriverId');
        _driverId = newDriverId;
        _listenToDriver();
      }
    });
  }

  // ─── LISTEN TO DRIVER'S LOCATION DOC ──────────

  void _listenToDriver() {
    _driverSub?.cancel();
    if (_driverId.isEmpty) return;

    debugPrint('[TrackDriver] 👂 Listening to drivers/$_driverId');

    _driverSub = FirebaseFirestore.instance
        .collection('drivers')
        .doc(_driverId)
        .snapshots()
        .listen((snapshot) {
      debugPrint('[TrackDriver] 📥 Driver snapshot: exists=${snapshot.exists}');
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data();
      if (data == null) return;

      final loc = DriverLocation.fromFirestore(data['currentLocation']);
      debugPrint('[TrackDriver] 📍 Parsed location: ${loc?.latitude}, ${loc?.longitude}');

      if (loc == null) {
        debugPrint('[TrackDriver] ❌ currentLocation null or malformed');
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
    final url = 'tel:$_driverPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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

  bool get _isStale =>
      DateTime.now().difference(_lastUpdate).inSeconds > 60;

  Map<String, dynamic> get _statusInfo {
    switch (_status) {
      case 'assigned':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF2563EB),
          'label': 'Driver Assigned',
          'description': 'Preparing to start the trip',
        };
      case 'on_the_way':
        return {
          'icon': Icons.local_shipping,
          'color': const Color(0xFFF59E0B),
          'label': 'On The Way',
          'description': 'Heading to your location',
        };
      case 'arrived':
        return {
          'icon': Icons.location_on,
          'color': const Color(0xFF10B981),
          'label': 'Driver Arrived',
          'description': 'Driver is at your location',
        };
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF10B981),
          'label': 'Completed',
          'description': 'Pickup completed successfully',
        };
      default:
        return {
          'icon': Icons.hourglass_empty,
          'color': const Color(0xFF6B7280),
          'label': 'Pending',
          'description': 'Waiting for driver assignment',
        };
    }
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text(
          'Track Driver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapSection(),
            if (_driverLoc != null && _status == 'on_the_way')
              _buildLiveBanner(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(statusInfo),
                  const SizedBox(height: 16),
                  if (_driverName.isNotEmpty) _buildDriverCard(),
                  const SizedBox(height: 16),
                  if (_driverLoc != null) _buildDistanceEtaCard(),
                  const SizedBox(height: 16),
                  if (_driverLoc == null) _buildWaitingCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAP SECTION ──────────────────────────────

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 340,
      color: Colors.grey[300],
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

              // Route polyline (blue)
              if (_route != null && _route!.polyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.polyline,
                      strokeWidth: 5.0,
                      color: _route!.isFallback
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF2563EB),
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
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFEF4444),
                        size: 42,
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
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Color(0xFF10B981),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Map controls
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

          // Route loading indicator
          if (_loadingRoute)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Updating route...',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
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

  // ─── LIVE BANNER ──────────────────────────────

  Widget _buildLiveBanner() {
    final stale = _isStale;
    final color = stale ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          if (!stale)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            )
          else
            Icon(Icons.wifi_off, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            stale ? 'Driver signal lost' : 'Live Tracking Active',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            'Updated $_lastUpdateText',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── STATUS CARD ──────────────────────────────

  Widget _buildStatusCard(Map<String, dynamic> statusInfo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (statusInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            statusInfo['icon'] as IconData,
            color: statusInfo['color'] as Color,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusInfo['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusInfo['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusInfo['description'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
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
            'Driver Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (_driverPhone.isNotEmpty)
                      Text(
                        _driverPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _callDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.phone, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DISTANCE / ETA CARD ──────────────────────

  Widget _buildDistanceEtaCard() {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.route,
                    color: Color(0xFF2563EB), size: 28),
                const SizedBox(height: 6),
                Text(
                  _distanceText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'Distance',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey[200]),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.timer,
                    color: Color(0xFFF59E0B), size: 28),
                const SizedBox(height: 6),
                Text(
                  _etaText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  'ETA',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── WAITING CARD ─────────────────────────────

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status == 'assigned'
                ? 'Waiting for driver to start the trip...'
                : 'Locating driver...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}