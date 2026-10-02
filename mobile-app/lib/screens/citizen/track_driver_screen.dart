// 📁 lib/screens/citizen/track_driver_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final MapController _mapController = MapController();

  LatLng? _pickupLocation;
  LatLng? _driverLocation;
  double? _distanceKm;
  bool _mapReady = false;
  String _driverName = '';
  String _driverPhone = '';
  String _status = 'assigned';

  static const LatLng _defaultCenter = LatLng(34.1558, 73.2194);

  @override
  void initState() {
    super.initState();
    _loadPickupLocation();
    _listenToRequest();
  }

  // ─── Load pickup location ───
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
      print('Error loading pickup location: $e');
    }
  }

  // ─── Listen to real-time updates ───
  void _listenToRequest() {
    FirebaseFirestore.instance
        .collection('pickupRequests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        _status = data['status'] ?? 'assigned';
        _driverName = data['driverName'] ?? '';
        _driverPhone = data['driverPhone'] ?? data['userPhone'] ?? '';

        // Driver location
        final driverLoc = data['driverLocation'];
        if (driverLoc != null) {
          final lat = driverLoc['latitude'];
          final lng = driverLoc['longitude'];
          if (lat != null && lng != null) {
            _driverLocation = LatLng(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            );

            // Calculate distance to pickup
            if (_pickupLocation != null) {
              _distanceKm = Geolocator.distanceBetween(
                    _driverLocation!.latitude,
                    _driverLocation!.longitude,
                    _pickupLocation!.latitude,
                    _pickupLocation!.longitude,
                  ) /
                  1000;
            }

            // Auto-follow driver marker
            if (_mapReady) {
              _mapController.move(_driverLocation!, 15);
            }
          }
        }
      });
    });
  }

  // ─── Distance text ───
  String get _distanceText {
    if (_distanceKm == null) return 'Calculating...';
    if (_distanceKm! < 0.1) return 'Less than 100m';
    return '${_distanceKm!.toStringAsFixed(1)} km';
  }

  // ─── ETA text ───
  String get _etaText {
    if (_distanceKm == null) return 'N/A';
    final minutes = (_distanceKm! / 30 * 60).round();
    if (minutes < 1) return '< 1 min';
    return '$minutes min';
  }

  // ─── Call driver ───
  Future<void> _callDriver() async {
    if (_driverPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = 'tel:$_driverPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // ─── Status info ───
  Map<String, dynamic> get _statusInfo {
    switch (_status) {
      case 'assigned':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF2563EB),
          'label': 'Driver Assigned',
          'description': 'Driver is preparing to start the trip',
        };
      case 'on_the_way':
        return {
          'icon': Icons.local_shipping,
          'color': const Color(0xFFF59E0B),
          'label': 'On The Way',
          'description': 'Driver is heading to your location',
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
            // ─── MAP ─────────────────────────
            Container(
              width: double.infinity,
              height: 320,
              decoration: const BoxDecoration(
                color: Colors.grey,
              ),
              child: ClipRRect(
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
                        // Pickup location (red pin)
                        if (_pickupLocation != null)
                          Marker(
                            point: _pickupLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFEF4444),
                              size: 45,
                            ),
                          ),
                        // Driver location (green truck)
                        if (_driverLocation != null)
                          Marker(
                            point: _driverLocation!,
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
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
                                size: 26,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── LIVE TRACKING BANNER ────────
            if (_driverLocation != null && _status == 'on_the_way')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: const Color(0xFF10B981).withOpacity(0.1),
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
                    const SizedBox(width: 8),
                    const Text(
                      'Live Tracking Active',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Updated in real-time',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // ─── DRIVER INFO CARD ────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Driver Details Card
                  if (_driverName.isNotEmpty)
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
                              // Avatar
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(0.1),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                              // Call button
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _callDriver,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(24),
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
                    ),

                  const SizedBox(height: 16),

                  // Distance/ETA Card
                  if (_driverLocation != null)
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.route,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _distanceText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'Distance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: Color(0xFFF59E0B),
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _etaText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'ETA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Waiting message (if no driver location yet)
                  if (_driverLocation == null)
                    Container(
                      width: double.infinity,
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
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
}