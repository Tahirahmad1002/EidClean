// 📁 lib/screens/driver/complete_pickup.dart
//
// Pickup completion screen:
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
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_widgets.dart';
import 'customer_review.dart';

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
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
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
                        // ─── REAL MAP ────────────────────────
                        _Reveal(index: 0, child: _buildMiniMap()),
                        const SizedBox(height: 14),

                        // ─── CUSTOMER CARD ───────────────────
                        _Reveal(
                          index: 1,
                          child: _buildCustomerCard(
                            userName: userName,
                            userPhone: userPhone,
                            location: location,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ─── PICKUP DETAILS ──────────────────
                        _Reveal(
                          index: 2,
                          child: _buildDetailsCard(
                            animals: animals,
                            wasteType: wasteType,
                            timeSlot: timeSlot,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── PHOTO SECTION ───────────────────
                        _Reveal(index: 3, child: _buildPhotoSection(hasPhoto)),
                        const SizedBox(height: 22),

                        // ─── NOTES ───────────────────────────
                        _Reveal(index: 4, child: _buildNotesSection()),
                        const SizedBox(height: 24),

                        // ─── SUBMIT ──────────────────────────
                        _Reveal(index: 5, child: _buildSubmitButton(hasPhoto)),
                        const SizedBox(height: 10),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complete Pickup',
                            style: AppTextStyles.h2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Take a photo to finish this task',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AuthColors.emerald200
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const AuthHeroChip(
                      icon: Icons.check_circle_rounded,
                      label: 'ARRIVED',
                    ),
                    if (widget.etaText != null)
                      AuthHeroChip(
                        icon: Icons.timer_rounded,
                        label: 'ETA ${widget.etaText!.toUpperCase()}',
                      ),
                    if (widget.distanceKm != null)
                      AuthHeroChip(
                        icon: Icons.straighten_rounded,
                        label: '${widget.distanceKm!.toStringAsFixed(1)} KM',
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

  // ─── MINI MAP ─────────────────────────────────

  Widget _buildMiniMap() {
    final tone = _Tones.emerald;

    return Container(
      height: 200,
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.eidclean_app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5.0,
                        color: _Tones.blue.to,
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
                        child: Icon(
                          Icons.location_on_rounded,
                          color: _Tones.rose.to,
                          size: 38,
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
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [tone.from, tone.to],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: tone.to.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
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
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tone.border),
                  boxShadow: [
                    BoxShadow(
                      color: tone.to.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: tone.to),
                    const SizedBox(width: 5),
                    Text(
                      'You have arrived',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: tone.fg,
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
    final tone = _Tones.emerald;

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
                          if (userPhone.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded,
                                    size: 13, color: tone.to),
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
                    if (widget.distanceKm != null)
                      _pill(
                        '${widget.distanceKm!.toStringAsFixed(1)} km',
                        tone,
                        icon: Icons.route_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
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
                      Icon(Icons.location_on_rounded,
                          size: 16, color: _Tones.rose.to),
                      const SizedBox(width: 6),
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
              ],
            ),
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
    final tone = _Tones.amber;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(14),
      decoration: _tintedCardDecoration(tone, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _gradientTile(Icons.inventory_2_rounded, tone, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
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
                    timeSlot.split(' ').first,
                    _Tones.emerald,
                    icon: Icons.schedule_rounded,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      'mixed': _Tones.indigo,
    };
    return _pill(type, tones[type] ?? _Tones.slate);
  }

  // ─── PHOTO SECTION ────────────────────────────

  Widget _buildPhotoSection(bool hasPhoto) {
    final tone = _Tones.emerald;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionHeader('Photo Required', 'Proof of pickup'),
            const Spacer(),
            if (hasPhoto)
              _pill('Captured', tone, icon: Icons.check_rounded),
          ],
        ),
        const SizedBox(height: 12),
        _PressScale(
          onTap: _capturePhoto,
          child: Container(
            width: double.infinity,
            height: hasPhoto ? 220 : 140,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: hasPhoto
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, tone.bg],
                    ),
              color: hasPhoto ? AppColors.slate900 : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasPhoto ? tone.to : tone.border,
                width: hasPhoto ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: tone.to.withValues(alpha: hasPhoto ? 0.28 : 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: hasPhoto
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPhotoWidget(),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AuthColors.emerald950
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Retake',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -30,
                        child: GlowCircle(
                          size: 140,
                          color: tone.from.withValues(alpha: 0.30),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _gradientTile(Icons.camera_alt_rounded, tone,
                                size: 54),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to open camera',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.w800,
                                color: tone.fg,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Photo is required to complete pickup',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
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
    final tone = _Tones.emerald;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Notes', 'Optional — any issues or special items'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tone.border, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: tone.to.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: AppTextStyles.body.copyWith(
              color: AppColors.slate900,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              hintText: 'Any issues, extra items, or notes...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.slate400,
                fontSize: 13.5,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────

  Widget _buildSubmitButton(bool hasPhoto) {
    return _ToneButton(
      label: _loading
          ? 'Submitting...'
          : (hasPhoto ? 'Complete Pickup' : 'Take Photo First'),
      icon: hasPhoto ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
      tone: hasPhoto ? _Tones.emerald : _Tones.slate,
      height: 56,
      loading: _loading,
      onTap: (_loading || !hasPhoto) ? null : _submitPickup,
    );
  }

  // ─── SHARED HELPERS ───────────────────────────

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

  Widget _sectionHeader(String title, String caption) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AuthColors.emerald400, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(caption, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _heroCircleButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return _PressScale(
      onTap: onTap ?? () {},
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