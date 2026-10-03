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
import 'focused_navigation_screen.dart';
import 'driver_home.dart';

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
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAF8),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          title: const Text('Active Route'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFEF4444), size: 48),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_sequence.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Active Route',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _safeExit,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Exit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _buildMap(),
          ),
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressHeader(),
                    const SizedBox(height: 16),
                    _buildActiveCard(),
                    if (_lockedStops.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildLockedSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY / SHIFT COMPLETE STATE ─────────────

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Active Route',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 28),

              // Headline
              const Text(
                'Shift Complete!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),

              // Subtext
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "You've completed all your pickups for today.\nGreat work! 🎉",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stats card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        icon: Icons.local_shipping,
                        label: 'Completed',
                        value: '$_completedCount',
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: _statItem(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: _sessionDurationLabel,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Primary action
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverHome(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard, size: 20),
                  label: const Text(
                    'Back to Dashboard',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    shadowColor:
                        const Color(0xFF10B981).withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── MAP WIDGET ───────────────────────────────

  Widget _buildMap() {
    final active = _activeStop;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _driverLocation ??
                active?.location ??
                _defaultCenter,
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
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF2563EB),
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
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFEF4444),
                      size: 48,
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
                          color: const Color(0xFF10B981),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Color(0xFF10B981),
                        size: 26,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_activeRoute != null)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_activeRoute!.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 16, color: Colors.grey[300]),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${_activeRoute!.durationMinutes.toStringAsFixed(0)} min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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
                onTap: _fitToActiveLeg,
              ),
            ],
          ),
        ),
      ],
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

  // ─── PROGRESS HEADER ──────────────────────────

  Widget _buildProgressHeader() {
    final total = _sequence.length + _completedCount;
    final current = _completedCount + 1;
    final progress = total == 0 ? 0.0 : current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pickup $current of $total',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      ],
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
    final wasteType = data['wasteType'] ?? 'mixed';
    final timeSlot = data['timeSlot'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (timeSlot.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeSlot.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (userPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  userPhone,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.pets, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '$animals Animal${animals > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                wasteType,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openFocusedNavigation,
              icon: const Icon(Icons.navigation, size: 20),
              label: const Text(
                'Start Navigation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
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
            const Icon(Icons.lock_outline,
                size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              'Upcoming (${_lockedStops.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}