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
        .where('status', whereIn: ['assigned', 'arrived'])
        .get();

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
        final seg = await RoutingService.instance
            .getRoute(points[i], points[i + 1]);
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
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .set({
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
            backgroundColor: Color(0xFF10B981),
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
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Optimize Route',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF10B981)),
          SizedBox(height: 16),
          Text('Finding best route...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _bootstrap,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 5,
          child: _buildMap(),
        ),

        // Bottom sheet
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optimized Sequence',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSequenceList(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildReasoningCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
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
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.eidclean_app',
            ),

            // Full route polyline
            if (_routeLine != null && _routeLine!.polyline.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routeLine!.polyline,
                    strokeWidth: 5.0,
                    color: const Color(0xFF2563EB),
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
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                  ),

                // Numbered stop markers
                ..._buildNumberedMarkers(),
              ],
            ),
          ],
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.route,
                    color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_stops.length} pickup${_stops.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildNumberedMarkers() {
    if (_optimizedRoute == null) return [];

    final markers = <Marker>[];
    for (var i = 0; i < _optimizedRoute!.orderedStops.length; i++) {
      final stop = _optimizedRoute!.orderedStops[i];
      markers.add(
        Marker(
          point: stop.location,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: _stopColor(stop.priority),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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

  Color _stopColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Widget _buildSequenceList() {
    if (_optimizedRoute == null) return const SizedBox();

    return Column(
      children: [
        _sequenceRow(
          icon: Icons.my_location,
          color: const Color(0xFF10B981),
          title: 'Start (Your location)',
          subtitle: 'Current GPS position',
          isLast: false,
        ),
        for (var i = 0; i < _optimizedRoute!.orderedStops.length; i++)
          _sequenceRow(
            icon: Icons.location_on,
            color: _stopColor(_optimizedRoute!.orderedStops[i].priority),
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
    required Color color,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    if (_optimizedRoute == null) return const SizedBox();

    return Container(
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
                const Icon(Icons.route, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  '${_optimizedRoute!.totalDistanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Total Distance',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  '${_optimizedRoute!.totalDurationMin.toStringAsFixed(0)} min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Est. Duration',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningCard() {
    if (_optimizedRoute == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome,
              color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _optimizedRoute!.reasoning,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loading || _accepting ? null : _bootstrap,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Recalculate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _accepting ? null : _acceptRoute,
            icon: _accepting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, size: 18),
            label: Text(_accepting ? 'Saving...' : 'Accept Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}