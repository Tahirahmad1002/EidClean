// 📁 lib/services/routing_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Result of a routing request.
class RouteResult {
  /// Road-following polyline (already parsed to LatLng list).
  final List<LatLng> polyline;

  /// Total distance in meters.
  final double distanceMeters;

  /// Total duration in seconds.
  final double durationSeconds;

  /// Which provider served the request.
  final String provider; // 'osrm' | 'ors' | 'straight-line-fallback'

  /// True if this is a degraded (straight-line) result.
  bool get isFallback => provider == 'straight-line-fallback';

  const RouteResult({
    required this.polyline,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.provider,
  });

  double get distanceKm => distanceMeters / 1000.0;
  double get durationMinutes => durationSeconds / 60.0;
}

/// Matrix result: distance[i][j] = meters from point i to point j.
class DistanceMatrix {
  final List<List<double>> distancesMeters;
  final List<List<double>> durationsSeconds;
  final String provider;

  const DistanceMatrix({
    required this.distancesMeters,
    required this.durationsSeconds,
    required this.provider,
  });
}

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  // ─── CONFIGURATION ────────────────────────────
  static const String _osrmBase = 'http://router.project-osrm.org';
  static const String _orsBase = 'https://api.openrouteservice.org';

  /// ⚠️ OPTIONAL: Add your own ORS key from https://openrouteservice.org/dev/#/signup
  /// Free tier: 2,000 requests/day. Leave empty to skip ORS fallback.
  static const String _orsApiKey = '';

  static const String _userAgent = 'EidCleanApp/1.0 (contact@eidclean.pk)';
  static const Duration _timeout = Duration(seconds: 8);
  static const Duration _cacheTtl = Duration(seconds: 60);

  // ─── CACHE ────────────────────────────────────
  final Map<String, _CacheEntry> _cache = {};

  // ─── PUBLIC API ───────────────────────────────

  /// Get a full road-following route between two coordinates.
  /// Falls back: OSRM → ORS → straight line.
  Future<RouteResult> getRoute(LatLng from, LatLng to) async {
    final key = _cacheKey([from, to]);
    final cached = _getCached(key);
    if (cached != null) {
      debugPrint('[RoutingService] ✅ Cache hit');
      return cached;
    }

    // Try OSRM first
    try {
      final result = await _getRouteFromOsrm(from, to);
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('[RoutingService] OSRM failed: $e');
    }

    // Try ORS fallback
    if (_orsApiKey.isNotEmpty) {
      try {
        final result = await _getRouteFromOrs(from, to);
        _setCache(key, result);
        return result;
      } catch (e) {
        debugPrint('[RoutingService] ORS failed: $e');
      }
    }

    // Last resort: straight line
    debugPrint('[RoutingService] ⚠️ Using straight-line fallback');
    return _straightLineResult(from, to);
  }

  /// Get distance/duration matrix between N points.
  /// Uses OSRM /table. For n ≤ 6 points this is fast and reliable.
  Future<DistanceMatrix> getDistanceMatrix(List<LatLng> points) async {
    if (points.length < 2) {
      throw ArgumentError('Need at least 2 points for matrix');
    }

    // Try OSRM
    try {
      return await _getMatrixFromOsrm(points);
    } catch (e) {
      debugPrint('[RoutingService] OSRM matrix failed: $e');
    }

    // Fallback: compute Haversine straight-line matrix
    debugPrint('[RoutingService] ⚠️ Using straight-line matrix fallback');
    return _straightLineMatrix(points);
  }

  // ─── OSRM ROUTE ───────────────────────────────

  Future<RouteResult> _getRouteFromOsrm(LatLng from, LatLng to) async {
    // ⚠️ OSRM uses lng,lat order — NOT lat,lng
    final coords = '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}';
    final url = Uri.parse(
      '$_osrmBase/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&steps=false',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': _userAgent},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('OSRM HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('OSRM returned no routes');
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    final polyline = coordinates.map<LatLng>((c) {
      final pair = c as List;
      return LatLng(
        (pair[1] as num).toDouble(), // lat
        (pair[0] as num).toDouble(), // lng
      );
    }).toList();

    return RouteResult(
      polyline: polyline,
      distanceMeters: (route['distance'] as num).toDouble(),
      durationSeconds: (route['duration'] as num).toDouble(),
      provider: 'osrm',
    );
  }

  // ─── OSRM MATRIX ──────────────────────────────

  Future<DistanceMatrix> _getMatrixFromOsrm(List<LatLng> points) async {
    final coordStr = points
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      '$_osrmBase/table/v1/driving/$coordStr'
      '?annotations=distance,duration',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': _userAgent},
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('OSRM table HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final distances = _parseMatrix(json['distances']);
    final durations = _parseMatrix(json['durations']);

    return DistanceMatrix(
      distancesMeters: distances,
      durationsSeconds: durations,
      provider: 'osrm',
    );
  }

  List<List<double>> _parseMatrix(dynamic raw) {
    if (raw == null) throw Exception('Matrix null');
    final rows = raw as List;
    return rows.map<List<double>>((row) {
      final cells = row as List;
      return cells.map<double>((v) {
        if (v == null) return double.infinity;
        return (v as num).toDouble();
      }).toList();
    }).toList();
  }

  // ─── ORS ROUTE (fallback) ─────────────────────

  Future<RouteResult> _getRouteFromOrs(LatLng from, LatLng to) async {
    final url = Uri.parse('$_orsBase/v2/directions/driving-car/geojson');

    final response = await http.post(
      url,
      headers: {
        'Authorization': _orsApiKey,
        'Content-Type': 'application/json',
        'User-Agent': _userAgent,
      },
      body: jsonEncode({
        'coordinates': [
          [from.longitude, from.latitude],
          [to.longitude, to.latitude],
        ],
      }),
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('ORS HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final features = json['features'] as List?;
    if (features == null || features.isEmpty) {
      throw Exception('ORS returned no features');
    }

    final feature = features.first as Map<String, dynamic>;
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;

    final polyline = coordinates.map<LatLng>((c) {
      final pair = c as List;
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();

    final props = feature['properties'] as Map<String, dynamic>;
    final summary = props['summary'] as Map<String, dynamic>;

    return RouteResult(
      polyline: polyline,
      distanceMeters: (summary['distance'] as num).toDouble(),
      durationSeconds: (summary['duration'] as num).toDouble(),
      provider: 'ors',
    );
  }

  // ─── STRAIGHT-LINE FALLBACKS ──────────────────

  RouteResult _straightLineResult(LatLng from, LatLng to) {
    const calc = Distance();
    final meters = calc.as(LengthUnit.Meter, from, to);
    // Assume average 30 km/h in city — rough
    final seconds = (meters / 1000.0) / 30.0 * 3600.0;
    return RouteResult(
      polyline: [from, to],
      distanceMeters: meters,
      durationSeconds: seconds,
      provider: 'straight-line-fallback',
    );
  }

  DistanceMatrix _straightLineMatrix(List<LatLng> points) {
    const calc = Distance();
    final n = points.length;
    final distances = List.generate(
      n,
      (_) => List<double>.filled(n, 0.0),
    );
    final durations = List.generate(
      n,
      (_) => List<double>.filled(n, 0.0),
    );

    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final m = calc.as(LengthUnit.Meter, points[i], points[j]);
        distances[i][j] = m;
        durations[i][j] = (m / 1000.0) / 30.0 * 3600.0;
      }
    }

    return DistanceMatrix(
      distancesMeters: distances,
      durationsSeconds: durations,
      provider: 'straight-line-fallback',
    );
  }

  // ─── CACHE HELPERS ────────────────────────────

  String _cacheKey(List<LatLng> points) {
    return points
        .map((p) =>
            '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}')
        .join('|');
  }

  RouteResult? _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.result;
  }

  void _setCache(String key, RouteResult result) {
    _cache[key] = _CacheEntry(result, DateTime.now());
    // Keep cache size bounded
    if (_cache.length > 50) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Debug helper: measure Haversine distance without hitting APIs.
  double straightLineMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }
}

class _CacheEntry {
  final RouteResult result;
  final DateTime timestamp;
  _CacheEntry(this.result, this.timestamp);
}

/// Utility: normalize heading to 0..360.
double normalizeHeading(double deg) => (deg % 360 + 360) % 360;

/// Utility: compute bearing (heading) from point A to point B in degrees.
double bearingBetween(LatLng a, LatLng b) {
  final lat1 = a.latitude * math.pi / 180.0;
  final lat2 = b.latitude * math.pi / 180.0;
  final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final brng = math.atan2(y, x) * 180.0 / math.pi;
  return normalizeHeading(brng);
}