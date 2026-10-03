// 📁 lib/screens/driver/complete_pickup.dart
//
// Pickup completion screen — polished with:
//   - Real mini-map showing driver → pickup route
//   - Compact info sections
//   - Photo capture as primary action
//   - Confirmation before submit

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/routing_service.dart';
import 'customer_review.dart';

class CompletePickup extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final double? distanceKm;
  final String? etaText;

  const CompletePickup({
    super.key,
    required this.taskId,
    required this.taskData,
    this.distanceKm,
    this.etaText,
  });

  @override
  State<CompletePickup> createState() => _CompletePickupState();
}

class _CompletePickupState extends State<CompletePickup> {
  // ─── FORM STATE ───────────────────────────────
  bool _loading = false;
  File? _photo;
  Uint8List? _webPhotoBytes;
  Uint8List? _mobilePhotoBytes;
  final TextEditingController _notesController = TextEditingController();

  // ─── MAP ──────────────────────────────────────
  final MapController _mapController = MapController();
  bool _mapReady = false;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  List<LatLng> _routePoints = [];

  static const Color _primary = Color(0xFF10B981);
  static const Color _darkTeal = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _loadPickupLocation();
    _loadDriverLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ─── LOAD LOCATIONS ───────────────────────────

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
      debugPrint('[CompletePickup] Pickup load error: $e');
    }
  }

  Future<void> _loadDriverLocation() async {
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
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(pos.latitude, pos.longitude);
          });
          _fetchRoute();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMap();
          });
        }
      }
    } catch (e) {
      debugPrint('[CompletePickup] Driver GPS error: $e');
      // Fallback to Firestore-synced position
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid;
      if (uid == null) return;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(uid)
            .get();
        final loc = doc.data()?['currentLocation'];
        if (loc is Map) {
          final lat = loc['latitude'];
          final lng = loc['longitude'];
          if (lat != null && lng != null && mounted) {
            setState(() {
              _driverLocation = LatLng(
                (lat as num).toDouble(),
                (lng as num).toDouble(),
              );
            });
            _fetchRoute();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitMap();
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;
    try {
      final result = await RoutingService.instance.getRoute(
        _driverLocation!,
        _pickupLocation!,
      );
      if (mounted) {
        setState(() {
          _routePoints = result.polyline;
        });
      }
    } catch (e) {
      debugPrint('[CompletePickup] Route error: $e');
    }
  }

  void _fitMap() {
    if (!_mapReady) return;
    final points = <LatLng>[];
    if (_driverLocation != null) points.add(_driverLocation!);
    if (_pickupLocation != null) points.add(_pickupLocation!);
    if (points.length < 2) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  // ─── PHOTO CAPTURE ────────────────────────────

  Future<void> _capturePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 60,
    );

    if (photo == null) return;

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _webPhotoBytes = bytes;
        _photo = null;
        _mobilePhotoBytes = null;
      });
    } else {
      final bytes = await photo.readAsBytes();
      setState(() {
        _photo = File(photo.path);
        _mobilePhotoBytes = bytes;
        _webPhotoBytes = null;
      });
    }
  }

  // ─── SUBMIT ───────────────────────────────────

  Future<void> _submitPickup() async {
    if (_photo == null && _webPhotoBytes == null) {
      _showSnack('Please take a photo before submitting', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      Uint8List? photoBytes;
      if (kIsWeb && _webPhotoBytes != null) {
        photoBytes = _webPhotoBytes;
      } else if (_mobilePhotoBytes != null) {
        photoBytes = _mobilePhotoBytes;
      } else if (_photo != null) {
        photoBytes = await _photo!.readAsBytes();
      }

      String? photoBase64;
      if (photoBytes != null) {
        photoBase64 = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';

        if (photoBase64.length > 950000) {
          setState(() => _loading = false);
          _showSnack(
            'Photo too large. Please retake with lower quality.',
            isError: true,
          );
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('pickupRequests')
          .doc(widget.taskId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'notes': _notesController.text.trim(),
        'photoBase64': photoBase64,
        'photoSize': photoBytes?.length ?? 0,
        'routeNeedsReoptimization': true,
      });

      if (!mounted) return;
      setState(() => _loading = false);

      _showSnack('Pickup completed successfully!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerReview(taskData: widget.taskData),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CompletePickup] Submit error: $e');
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFEF4444) : _primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = widget.taskData;
    final userName = data['userName'] ?? 'Customer';
    final userPhone = data['userPhone'] ?? '';
    final location = data['location'] ?? 'Pickup location';
    final animals = data['animals'] ?? 1;
    final wasteType = data['wasteType'] ?? 'mixed';
    final timeSlot = data['timeSlot'] ?? '';
    final hasPhoto = _photo != null || _webPhotoBytes != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complete Pickup',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (widget.etaText != null)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    widget.etaText!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── REAL MAP ────────────────────────
            _buildMiniMap(),
            const SizedBox(height: 14),

            // ─── CUSTOMER CARD ───────────────────
            _buildCustomerCard(
              userName: userName,
              userPhone: userPhone,
              location: location,
            ),
            const SizedBox(height: 14),

            // ─── PICKUP DETAILS ──────────────────
            _buildDetailsCard(
              animals: animals,
              wasteType: wasteType,
              timeSlot: timeSlot,
            ),
            const SizedBox(height: 20),

            // ─── PHOTO SECTION ───────────────────
            _buildPhotoSection(hasPhoto),
            const SizedBox(height: 16),

            // ─── NOTES ───────────────────────────
            _buildNotesSection(),
            const SizedBox(height: 20),

            // ─── SUBMIT ──────────────────────────
            _buildSubmitButton(hasPhoto),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ─── MINI MAP ─────────────────────────────────

  Widget _buildMiniMap() {
    return Container(
      height: 180,
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
                initialCenter:
                    _pickupLocation ?? const LatLng(34.1558, 73.2194),
                initialZoom: 14,
                onMapReady: () {
                  _mapReady = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fitMap();
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.eidclean_app',
                ),

                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    if (_pickupLocation != null)
                      Marker(
                        point: _pickupLocation!,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFEF4444),
                          size: 38,
                        ),
                      ),
                    if (_driverLocation != null)
                      Marker(
                        point: _driverLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Overlay pill
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: _primary),
                    const SizedBox(width: 5),
                    Text(
                      'You have arrived',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CUSTOMER CARD ────────────────────────────

  Widget _buildCustomerCard({
    required String userName,
    required String userPhone,
    required String location,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: _primary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
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
              if (widget.distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── DETAILS CARD ─────────────────────────────

  Widget _buildDetailsCard({
    required int animals,
    required String wasteType,
    required String timeSlot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _detailChip(
            icon: Icons.pets,
            label: '$animals Animal${animals > 1 ? 's' : ''}',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          _detailChip(
            icon: Icons.delete_outline,
            label: wasteType,
            color: const Color(0xFF6366F1),
          ),
          if (timeSlot.isNotEmpty) ...[
            const SizedBox(width: 10),
            _detailChip(
              icon: Icons.access_time,
              label: timeSlot.split(' ').first,
              color: _darkTeal,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PHOTO SECTION ────────────────────────────

  Widget _buildPhotoSection(bool hasPhoto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photo Required',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
            const Spacer(),
            if (hasPhoto)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check, size: 12, color: _primary),
                    SizedBox(width: 3),
                    Text(
                      'Captured',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _capturePhoto,
          child: Container(
            width: double.infinity,
            height: hasPhoto ? 200 : 130,
            decoration: BoxDecoration(
              color: hasPhoto ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasPhoto
                    ? _primary
                    : const Color(0xFFD1D5DB),
                width: hasPhoto ? 2 : 1.5,
              ),
            ),
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildPhotoWidget(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: _primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to open camera',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      Text(
                        'Photo is required to complete pickup',
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

  Widget _buildPhotoWidget() {
    if (_photo != null) {
      return Image.file(_photo!, fit: BoxFit.cover);
    }
    if (_webPhotoBytes != null) {
      return Image.memory(_webPhotoBytes!, fit: BoxFit.cover);
    }
    if (_mobilePhotoBytes != null) {
      return Image.memory(_mobilePhotoBytes!, fit: BoxFit.cover);
    }
    return const SizedBox();
  }

  // ─── NOTES SECTION ────────────────────────────

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Optional — any issues or special items',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Any issues, extra items, or notes...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────

  Widget _buildSubmitButton(bool hasPhoto) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (_loading || !hasPhoto) ? null : _submitPickup,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Icon(
                hasPhoto ? Icons.check_circle : Icons.camera_alt,
                size: 22,
              ),
        label: Text(
          _loading
              ? 'Submitting...'
              : (hasPhoto
                  ? 'Complete Pickup'
                  : 'Take Photo First'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPhoto ? _primary : const Color(0xFF9CA3AF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD1D5DB),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: hasPhoto ? 3 : 0,
        ),
      ),
    );
  }
}