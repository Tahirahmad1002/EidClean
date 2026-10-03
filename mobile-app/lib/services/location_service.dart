// 📁 lib/services/location_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// EidClean Driver Location Service
/// 
/// Streams real GPS from driver's phone to Firestore at
/// `drivers/{driverId}.currentLocation` with adaptive throttling.
/// 
/// Design notes:
/// - Writes every 10s OR when driver moves > 15m (whichever first)
/// - Skips GPS pings with accuracy > 50m (noisy signal)
/// - Stores heading (for marker rotation) + speed + accuracy
/// - Never crashes — all errors are caught & logged
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ─── CONFIGURATION ────────────────────────────
  static const Duration _minWriteInterval = Duration(seconds: 10);
  static const Duration _maxWriteInterval = Duration(seconds: 30);
  static const double _movementThresholdMeters = 15.0;
  static const double _maxAcceptableAccuracyMeters = 50.0;

  // ─── STATE ────────────────────────────────────
  StreamSubscription<Position>? _positionSub;
  Timer? _forceWriteTimer;
  Position? _lastWrittenPosition;
  DateTime? _lastWriteTime;
  String? _currentDriverId;
  String? _currentTaskId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // ─── PUBLIC API ───────────────────────────────

  /// Start streaming GPS for the given driver.
  /// Optionally attach a task ID (set when driver is on a trip).
  Future<bool> startTracking({
    required String driverId,
    String? taskId,
  }) async {
    if (_isTracking && _currentDriverId == driverId) {
      debugPrint('[LocationService] Already tracking $driverId');
      return true;
    }

    // Stop any previous tracking
    await stopTracking(updateFirestore: false);

    // ─── 1. Check GPS service enabled ───
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] ❌ Location services disabled');
      return false;
    }

    // ─── 2. Request permission ───
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] ❌ Permission denied');
      return false;
    }

    // ─── 3. Set state ───
    _currentDriverId = driverId;
    _currentTaskId = taskId;
    _isTracking = true;
    _lastWrittenPosition = null;
    _lastWriteTime = null;

    // ─── 4. Force initial write ───
    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      await _writeToFirestore(initial, force: true);
    } catch (e) {
      debugPrint('[LocationService] Initial position failed: $e');
    }

    // ─── 5. Subscribe to position stream ───
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters — OS-level throttle
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPosition,
      onError: (e) => debugPrint('[LocationService] Stream error: $e'),
    );

    // ─── 6. Force-write timer (for stationary drivers) ───
    _forceWriteTimer = Timer.periodic(_maxWriteInterval, (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        await _writeToFirestore(pos, force: true);
      } catch (e) {
        debugPrint('[LocationService] Force-write failed: $e');
      }
    });

    debugPrint('[LocationService] ✅ Tracking started for $driverId');
    return true;
  }

  /// Stop GPS streaming. Optionally clear Firestore location.
  Future<void> stopTracking({bool updateFirestore = true}) async {
    if (!_isTracking) return;

    _positionSub?.cancel();
    _positionSub = null;
    _forceWriteTimer?.cancel();
    _forceWriteTimer = null;

    if (updateFirestore && _currentDriverId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_currentDriverId)
            .update({
          'currentLocation.isTracking': false,
          'currentLocation.updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('[LocationService] Cleanup write failed: $e');
      }
    }

    debugPrint('[LocationService] 🛑 Tracking stopped');
    _isTracking = false;
    _currentDriverId = null;
    _currentTaskId = null;
    _lastWrittenPosition = null;
    _lastWriteTime = null;
  }

  /// Update the active task ID mid-trip (rare use case).
  void attachTask(String taskId) {
    _currentTaskId = taskId;
  }

  // ─── INTERNAL LOGIC ───────────────────────────

  void _onPosition(Position pos) {
    // Ignore noisy pings
    if (pos.accuracy > _maxAcceptableAccuracyMeters) {
      debugPrint('[LocationService] Ignoring ping (accuracy ${pos.accuracy}m)');
      return;
    }

    final shouldWrite = _shouldWrite(pos);
    if (shouldWrite) {
      _writeToFirestore(pos);
    }
  }

  bool _shouldWrite(Position pos) {
    // First write after start
    if (_lastWrittenPosition == null || _lastWriteTime == null) {
      return true;
    }

    // Time-based write
    final elapsed = DateTime.now().difference(_lastWriteTime!);
    if (elapsed >= _minWriteInterval) {
      // But also check movement — if still, use max interval
      if (elapsed >= _maxWriteInterval) return true;
    }

    // Movement-based write
    final distance = Geolocator.distanceBetween(
      _lastWrittenPosition!.latitude,
      _lastWrittenPosition!.longitude,
      pos.latitude,
      pos.longitude,
    );
    return distance >= _movementThresholdMeters;
  }

  Future<void> _writeToFirestore(Position pos, {bool force = false}) async {
    if (_currentDriverId == null) return;
    if (!force && !_shouldWrite(pos)) return;

    try {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentDriverId)
          .set({
        'currentLocation': {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'heading': pos.heading,
          'speed': pos.speed,
          'accuracy': pos.accuracy,
          'isTracking': true,
          'activeTaskId': _currentTaskId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      _lastWrittenPosition = pos;
      _lastWriteTime = DateTime.now();

      debugPrint(
        '[LocationService] 📍 Wrote (${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)}) '
        '±${pos.accuracy.toStringAsFixed(0)}m',
      );
    } catch (e) {
      debugPrint('[LocationService] ❌ Write failed: $e');
    }
  }
}