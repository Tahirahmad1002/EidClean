// 📁 lib/models/driver_location.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Typed model representing a driver's live GPS location
/// as stored in Firestore at `drivers/{driverId}.currentLocation`.
///
/// Firestore schema:
/// ```
/// currentLocation: {
///   latitude: 34.1522,
///   longitude: 73.2025,
///   heading: 187.4,
///   speed: 8.3,
///   accuracy: 12.5,
///   isTracking: true,
///   activeTaskId: "request_abc123",
///   updatedAt: <serverTimestamp>
/// }
/// ```
class DriverLocation {
  final double latitude;
  final double longitude;

  /// Direction of travel in degrees (0 = North, 90 = East, etc.)
  /// null if device doesn't report heading.
  final double? heading;

  /// Speed in meters/second. null if device doesn't report.
  final double? speed;

  /// GPS accuracy radius in meters (smaller = better).
  final double? accuracy;

  /// True if the driver app is actively streaming location.
  final bool isTracking;

  /// Task ID currently in progress (null if driver is idle).
  final String? activeTaskId;

  /// When this position was last updated (server time).
  final DateTime? updatedAt;

  const DriverLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    this.isTracking = true,
    this.activeTaskId,
    this.updatedAt,
  });

  // ─── CONVENIENCE ──────────────────────────────

  LatLng get latLng => LatLng(latitude, longitude);

  /// Speed in km/h (from m/s).
  double? get speedKmh => speed == null ? null : speed! * 3.6;

  /// True if this location is "fresh" (updated within last 60 seconds).
  bool get isFresh {
    if (updatedAt == null) return false;
    final age = DateTime.now().difference(updatedAt!);
    return age.inSeconds <= 60;
  }

  /// True if the driver appears to be moving.
  bool get isMoving => (speed ?? 0) > 1.0; // > 1 m/s ≈ 3.6 km/h

  // ─── FACTORY CONSTRUCTORS ─────────────────────

  /// Build from a Firestore document map.
  /// Returns null if required fields missing.
  ///
  /// Accepts either:
  ///   - The `currentLocation` sub-map: `data['currentLocation']`
  ///   - A raw field map with `latitude`/`longitude` keys
  static DriverLocation? fromFirestore(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);

    final lat = _asDouble(map['latitude']);
    final lng = _asDouble(map['longitude']);
    if (lat == null || lng == null) return null;

    return DriverLocation(
      latitude: lat,
      longitude: lng,
      heading: _asDouble(map['heading']),
      speed: _asDouble(map['speed']),
      accuracy: _asDouble(map['accuracy']),
      isTracking: (map['isTracking'] as bool?) ?? true,
      activeTaskId: map['activeTaskId'] as String?,
      updatedAt: _asDate(map['updatedAt']),
    );
  }

  /// Build from explicit LatLng (e.g., driver's own position).
  factory DriverLocation.fromLatLng(
    LatLng pos, {
    bool isTracking = true,
    String? activeTaskId,
  }) {
    return DriverLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      isTracking: isTracking,
      activeTaskId: activeTaskId,
      updatedAt: DateTime.now(),
    );
  }

  // ─── SERIALIZATION ────────────────────────────

  /// Convert to a Firestore-friendly map.
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (accuracy != null) 'accuracy': accuracy,
      'isTracking': isTracking,
      if (activeTaskId != null) 'activeTaskId': activeTaskId,
      // Note: updatedAt is set by caller as FieldValue.serverTimestamp()
    };
  }

  // ─── COPY WITH ────────────────────────────────

  DriverLocation copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? accuracy,
    bool? isTracking,
    String? activeTaskId,
    DateTime? updatedAt,
  }) {
    return DriverLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
      isTracking: isTracking ?? this.isTracking,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DriverLocation('
        'lat: ${latitude.toStringAsFixed(5)}, '
        'lng: ${longitude.toStringAsFixed(5)}, '
        'heading: ${heading?.toStringAsFixed(1) ?? "—"}, '
        'speed: ${speedKmh?.toStringAsFixed(1) ?? "—"} km/h, '
        'tracking: $isTracking'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.heading == heading &&
        other.speed == speed &&
        other.accuracy == accuracy &&
        other.isTracking == isTracking &&
        other.activeTaskId == activeTaskId;
  }

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        heading,
        speed,
        accuracy,
        isTracking,
        activeTaskId,
      );
}

// ─── PRIVATE HELPERS ────────────────────────────

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return null;
}