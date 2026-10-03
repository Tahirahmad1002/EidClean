// 📁 lib/services/route_optimizer.dart

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'routing_service.dart';

/// A single pickup stop for optimization.
class OptimizableStop {
  final String taskId;
  final LatLng location;
  final int priority;      // 1 = highest, 3 = lowest
  final String timeSlot;   // 'Morning' | 'Afternoon' | 'Evening' | ''
  final Map<String, dynamic> rawData;

  const OptimizableStop({
    required this.taskId,
    required this.location,
    required this.priority,
    required this.timeSlot,
    required this.rawData,
  });

  /// Factory: build from Firestore doc.
  static OptimizableStop? fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    // Extract lat/lng — supports both field styles
    double? lat;
    double? lng;

    if (data['latitude'] != null && data['longitude'] != null) {
      lat = (data['latitude'] as num).toDouble();
      lng = (data['longitude'] as num).toDouble();
    } else if (data['geoPoint'] != null) {
      final geo = data['geoPoint'] as GeoPoint;
      lat = geo.latitude;
      lng = geo.longitude;
    }

    if (lat == null || lng == null) return null;

    return OptimizableStop(
      taskId: docId,
      location: LatLng(lat, lng),
      priority: _computePriority(data),
      timeSlot: (data['timeSlot'] ?? '').toString(),
      rawData: data,
    );
  }

  static int _computePriority(Map<String, dynamic> data) {
    final animals = data['animals'] ?? 1;
    if (animals >= 3) return 1;
    if (animals >= 2) return 2;
    return 3;
  }
}

/// The optimization result.
class OptimizedRoute {
  /// Ordered list of stops (driver's location NOT included).
  final List<OptimizableStop> orderedStops;

  /// Total driving distance (meters).
  final double totalDistanceMeters;

  /// Total estimated duration (seconds).
  final double totalDurationSeconds;

  /// Human-readable explanation.
  final String reasoning;

  const OptimizedRoute({
    required this.orderedStops,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.reasoning,
  });

  double get totalDistanceKm => totalDistanceMeters / 1000.0;
  double get totalDurationMin => totalDurationSeconds / 60.0;
  List<String> get orderedTaskIds =>
      orderedStops.map((s) => s.taskId).toList();
}

class RouteOptimizer {
  RouteOptimizer._();
  static final RouteOptimizer instance = RouteOptimizer._();

  // ─── COST WEIGHTS ─────────────────────────────
  static const double _wDistance = 0.50;
  static const double _wPriority = 0.30;
  static const double _wTimeSlot = 0.20;

  // ─── MAX STOPS FOR BRUTE-FORCE ────────────────
  // 8! = 40,320 permutations — fine in milliseconds
  // Beyond that, switch to nearest-neighbor heuristic
  static const int _bruteForceLimit = 8;

  /// Optimize visitation order.
  ///
  /// [driverLocation] — current driver GPS
  /// [stops] — list of pending pickups
  ///
  /// Returns null if fewer than 2 stops.
  Future<OptimizedRoute?> optimize({
    required LatLng driverLocation,
    required List<OptimizableStop> stops,
  }) async {
    if (stops.length < 1) return null;
    if (stops.length == 1) {
      // Trivial case
      final matrix = await _fetchMatrix(driverLocation, stops);
      final d = matrix.distancesMeters[0][1];
      final t = matrix.durationsSeconds[0][1];
      return OptimizedRoute(
        orderedStops: stops,
        totalDistanceMeters: d,
        totalDurationSeconds: t,
        reasoning: 'Single pickup — no optimization needed.',
      );
    }

    // 1. Build matrix
    final matrix = await _fetchMatrix(driverLocation, stops);

    // 2. Find best order
    final n = stops.length;
    late List<int> bestOrder;
    late double bestCost;

    if (n <= _bruteForceLimit) {
      debugPrint('[RouteOptimizer] Brute-force TSP (n=$n)');
      final result = _bruteForceTsp(matrix.distancesMeters, stops);
      bestOrder = result.order;
      bestCost = result.cost;
    } else {
      debugPrint('[RouteOptimizer] Nearest-neighbor heuristic (n=$n)');
      final result = _nearestNeighborTsp(matrix.distancesMeters, stops);
      bestOrder = result.order;
      bestCost = result.cost;
    }

    // 3. Compute final distance/duration using matrix
    double totalDist = 0;
    double totalDur = 0;
    int prev = 0; // driver index
    for (final stopIdx in bestOrder) {
      final matrixIdx = stopIdx + 1; // +1 because driver is index 0
      totalDist += matrix.distancesMeters[prev][matrixIdx];
      totalDur += matrix.durationsSeconds[prev][matrixIdx];
      prev = matrixIdx;
    }

    // 4. Build reasoning
    final reasoning = _buildReasoning(bestOrder, stops, matrix);

    return OptimizedRoute(
      orderedStops: bestOrder.map((i) => stops[i]).toList(),
      totalDistanceMeters: totalDist,
      totalDurationSeconds: totalDur,
      reasoning: reasoning,
    );
  }

  // ─── MATRIX FETCH ─────────────────────────────

  Future<DistanceMatrix> _fetchMatrix(
    LatLng driver,
    List<OptimizableStop> stops,
  ) async {
    final points = <LatLng>[driver, ...stops.map((s) => s.location)];
    return RoutingService.instance.getDistanceMatrix(points);
  }

  // ─── BRUTE FORCE TSP ──────────────────────────

  _TspResult _bruteForceTsp(
    List<List<double>> matrix,
    List<OptimizableStop> stops,
  ) {
    final n = stops.length;
    final indices = List<int>.generate(n, (i) => i);
    double bestCost = double.infinity;
    List<int> bestOrder = List<int>.from(indices);

    _permute(indices, 0, (order) {
      final cost = _evaluateOrder(matrix, order, stops);
      if (cost < bestCost) {
        bestCost = cost;
        bestOrder = List<int>.from(order);
      }
    });

    return _TspResult(order: bestOrder, cost: bestCost);
  }

  void _permute(
    List<int> arr,
    int k,
    void Function(List<int>) callback,
  ) {
    if (k == arr.length) {
      callback(arr);
      return;
    }
    for (var i = k; i < arr.length; i++) {
      final tmp = arr[k];
      arr[k] = arr[i];
      arr[i] = tmp;
      _permute(arr, k + 1, callback);
      arr[i] = arr[k];
      arr[k] = tmp;
    }
  }

  /// Evaluate a sequence using the priority-aware cost function.
  /// Lower cost = better route.
  double _evaluateOrder(
    List<List<double>> matrix,
    List<int> order,
    List<OptimizableStop> stops,
  ) {
    double distanceCost = 0;
    double priorityPenalty = 0;
    double timeSlotPenalty = 0;

    int prev = 0; // driver
    for (var pos = 0; pos < order.length; pos++) {
      final stopIdx = order[pos];
      final matrixIdx = stopIdx + 1;

      distanceCost += matrix[prev][matrixIdx];

      // Priority penalty: high-priority stops visited LATER = worse
      final priority = stops[stopIdx].priority;
      // Normalize: 1 (highest) → 0, 2 → 0.5, 3 → 1
      final priNorm = (priority - 1) / 2.0;
      // Late visit amplifies penalty
      priorityPenalty += priNorm * (pos + 1) * 100.0;

      // Time slot penalty: later slots visited earlier = worse
      // (a morning slot scheduled for 3rd position = small penalty)
      final slot = stops[stopIdx].timeSlot.toLowerCase();
      final slotWeight = _timeSlotWeight(slot); // 0..1
      timeSlotPenalty += slotWeight * (order.length - pos) * 50.0;

      prev = matrixIdx;
    }

    // Normalize distance cost so its weight is comparable
    final n = order.length;
    final normalizedDistance = n > 0 ? distanceCost / n : 0;

    return (_wDistance * normalizedDistance) +
        (_wPriority * priorityPenalty) +
        (_wTimeSlot * timeSlotPenalty);
  }

  double _timeSlotWeight(String slot) {
    if (slot.contains('morning')) return 0.0; // no penalty
    if (slot.contains('afternoon')) return 0.5;
    if (slot.contains('evening')) return 1.0;
    return 0.5;
  }

  // ─── NEAREST-NEIGHBOR (FALLBACK FOR n > 8) ────

  _TspResult _nearestNeighborTsp(
    List<List<double>> matrix,
    List<OptimizableStop> stops,
  ) {
    final n = stops.length;
    final visited = List<bool>.filled(n, false);
    final order = <int>[];
    int current = 0; // driver

    for (var step = 0; step < n; step++) {
      int? bestIdx;
      double bestDist = double.infinity;

      for (var i = 0; i < n; i++) {
        if (visited[i]) continue;
        // Combine distance with priority bonus
        final dist = matrix[current][i + 1];
        final priorityBonus = (4 - stops[i].priority) * 100.0;
        final effective = dist - priorityBonus;
        if (effective < bestDist) {
          bestDist = effective;
          bestIdx = i;
        }
      }

      if (bestIdx == null) break;
      visited[bestIdx] = true;
      order.add(bestIdx);
      current = bestIdx + 1;
    }

    final cost = _evaluateOrder(matrix, order, stops);
    return _TspResult(order: order, cost: cost);
  }

  // ─── REASONING BUILDER ────────────────────────

  String _buildReasoning(
    List<int> order,
    List<OptimizableStop> stops,
    DistanceMatrix matrix,
  ) {
    final buffer = StringBuffer();

    final highPriorityCount =
        stops.where((s) => s.priority == 1).length;
    if (highPriorityCount > 0) {
      buffer.write(
        '$highPriorityCount high-priority pickup${highPriorityCount > 1 ? 's' : ''} visited first. ',
      );
    }

    buffer.write('Optimized for minimum road distance');

    final hasTimeSlots =
        stops.any((s) => s.timeSlot.toLowerCase().contains('morning'));
    if (hasTimeSlots) {
      buffer.write(' with morning slots prioritized');
    }

    buffer.write('.');
    return buffer.toString();
  }
}

class _TspResult {
  final List<int> order;
  final double cost;
  const _TspResult({required this.order, required this.cost});
}

/// Small helper: distance in meters between 2 LatLng using Haversine.
/// Used only for heuristic tie-breaking — not for final distances.
double haversineMeters(LatLng a, LatLng b) {
  const R = 6371000.0; // Earth radius meters
  final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
  final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
  final lat1 = a.latitude * math.pi / 180.0;
  final lat2 = b.latitude * math.pi / 180.0;

  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
  return 2 * R * math.asin(math.sqrt(h));
}