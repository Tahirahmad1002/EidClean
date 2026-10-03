// 📁 lib/screens/driver/driver_task_detail.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';                    // ✅ NEW: For Timer
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
  String _status = 'assigned';
  final MapController _mapController = MapController();

  LatLng? _pickupLocation;
  LatLng? _driverLocation;
  double? _distanceKm;
  bool _loadingLocation = true;
  bool _mapReady = false;

  // ✅ NEW: Trip tracking state
  bool _isTripActive = false;
  Timer? _tripTimer;
  double _progress = 0.0;         // 0.0 to 1.0

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _status = widget.taskData['status'] ?? 'assigned';
    _loadPickupLocation();
    _loadDriverLocation();
  }

  @override
  void dispose() {
    _tripTimer?.cancel();          // ✅ NEW: Clean up timer
    super.dispose();
  }

  // ─── LOAD PICKUP LOCATION ───
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
      print('Error loading pickup location: $e');
    }
  }

  // ─── LOAD DRIVER LOCATION (GPS) ───
  Future<void> _loadDriverLocation() async {
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

        if (_pickupLocation != null) {
          _distanceKm = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                _pickupLocation!.latitude,
                _pickupLocation!.longitude,
              ) /
              1000;
        }
      }
    } catch (e) {
      print('Driver location error: $e');
    }

    if (mounted) {
      setState(() => _loadingLocation = false);

      if (_mapReady && _pickupLocation != null) {
        _mapController.move(_pickupLocation!, 15);
      }
    }
  }

  // ✅ NEW: START TRIP (Simulation)
  void _startTrip() {
    if (_pickupLocation == null || _driverLocation == null) return;

    setState(() {
      _isTripActive = true;
      _progress = 0.0;
    });

    // Update status in Firestore
    _updateStatus('on_the_way');

    // Send initial driver location
    _sendDriverLocation();

    // Start simulation: move driver 5% closer every 3 seconds
    _tripTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_progress >= 1.0) {
        timer.cancel();
        setState(() {
          _isTripActive = false;
          _progress = 1.0;
        });
        _updateStatus('arrived');
        return;
      }

      // Move driver 5% closer to pickup
      setState(() {
        _progress = (_progress + 0.05).clamp(0.0, 1.0);

        // Interpolate location
        final startLat = widget.taskData['latitude'] != null
            ? (widget.taskData['latitude'] as num).toDouble()
            : _pickupLocation!.latitude;

        final startLng = widget.taskData['longitude'] != null
            ? (widget.taskData['longitude'] as num).toDouble()
            : _pickupLocation!.longitude;

        // Simulated driver start (some distance away)
        final driverStartLat = startLat - 0.01;
        final driverStartLng = startLng - 0.01;

        _driverLocation = LatLng(
          driverStartLat + ((startLat - driverStartLat) * _progress),
          driverStartLng + ((startLng - driverStartLng) * _progress),
        );

        // Recalculate distance
        if (_pickupLocation != null) {
          _distanceKm = Geolocator.distanceBetween(
                _driverLocation!.latitude,
                _driverLocation!.longitude,
                _pickupLocation!.latitude,
                _pickupLocation!.longitude,
              ) /
              1000;
        }
      });

      // Move map to follow driver
      if (_mapReady && _driverLocation != null) {
        _mapController.move(_driverLocation!, 15);
      }

      // Send updated location to Firestore
      _sendDriverLocation();
    });
  }

  // ✅ NEW: STOP TRIP
  void _stopTrip() {
    _tripTimer?.cancel();
    setState(() {
      _isTripActive = false;
    });
    _updateStatus('assigned');
  }

  // ✅ NEW: SEND DRIVER LOCATION TO FIRESTORE
  Future<void> _sendDriverLocation() async {
    if (_driverLocation == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'driverLocation': {
          'latitude': _driverLocation!.latitude,
          'longitude': _driverLocation!.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
          'isTracking': _isTripActive,
        },
      });
      print('📍 Location sent: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  // ─── OPEN NAVIGATION ─────
  Future<void> _openNavigation() async {
    if (_pickupLocation == null) return;

    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${_pickupLocation!.latitude},${_pickupLocation!.longitude}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation')),
        );
      }
    }
  }

  // ─── CALL CUSTOMER ─────
  Future<void> _callCustomer() async {
    final phone = widget.taskData['userPhone'] ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // ─── DISTANCE TEXT ─────
  String get _distanceText {
    if (_distanceKm == null) return 'Calculating...';
    if (_distanceKm! < 0.1) return 'Less than 100m';
    return '${_distanceKm!.toStringAsFixed(1)} km away';
  }

  // ─── ETA TEXT ─────
  String get _etaText {
    if (_distanceKm == null) return 'N/A';
    final minutes = (_distanceKm! / 30 * 60).round();
    if (minutes < 1) return '< 1 min';
    return '$minutes min';
  }

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
            // ─── MAP AREA ─────────────────────
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickupLocation ?? _defaultCenter,
                    initialZoom: 15,
                    onMapReady: () {
                      setState(() => _mapReady = true);
                      if (_pickupLocation != null) {
                        _mapController.move(_pickupLocation!, 15);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.eidclean_app',
                    ),
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
                              size: 40,
                            ),
                          ),
                        if (_driverLocation != null)
                          Marker(
                            point: _driverLocation!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
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
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ NEW: START/STOP TRIP BUTTON
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isTripActive ? _stopTrip : _startTrip,
                icon: Icon(
                  _isTripActive ? Icons.stop_circle : Icons.play_circle,
                  size: 24,
                ),
                label: Text(
                  _isTripActive ? 'Stop Trip' : 'Start Trip',
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
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            // ✅ NEW: Trip Progress Bar
            if (_isTripActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping,
                            size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        const Text(
                          'Trip In Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ─── NAVIGATE + CALL BUTTONS ─────
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      icon: const Icon(Icons.navigation, size: 20),
                      label: const Text(
                        'Navigate',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.phone, size: 22),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── NEXT PICKUP CARD ─────────────
            Container(
              width: double.infinity,
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
                    'Next Pickup',
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
                        Icon(Icons.phone,
                            size: 14, color: Colors.grey[500]),
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
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[500]),
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
                      Icon(Icons.pets,
                          size: 16, color: Colors.grey[500]),
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

                  const Divider(height: 20),

                  Row(
                    children: [
                      const Icon(Icons.route,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        _distanceText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.timer,
                          size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'ETA: $_etaText',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
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
            ),
            const SizedBox(height: 20),

            // ─── ARRIVED BUTTON ──────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  _tripTimer?.cancel();
                  _updateStatus('arrived');
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
                },
                icon: const Icon(Icons.location_on),
                label: const Text(
                  "I've Arrived at Location",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Status updated to: $newStatus');
    } catch (e) {
      print('Error updating status: $e');
    }
  }

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