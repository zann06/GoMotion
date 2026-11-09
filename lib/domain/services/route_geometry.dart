import 'dart:math' as math;

import '../entities/fixtures.dart';

/// Builds deterministic schematic polylines between two map points.
///
/// `docs/SIMULATION_ENGINE.md` says to represent routes as normalised points on
/// the illustrated map and animate a marker between those points. There is no
/// pathfinding service and no road graph, so this produces a stable, believable
/// "elbow" route from a fixed interpolation rule.
abstract final class RouteGeometry {
  /// Number of segments inserted between origin and destination.
  static const int _waypointCount = 3;

  /// Returns a polyline from [from] to [to] with intermediate bends.
  ///
  /// The bends are derived only from the endpoints, so the same pair of points
  /// always yields the same route. That keeps replay and tests deterministic.
  static List<MapPoint> between(MapPoint from, MapPoint to) {
    final points = <MapPoint>[from];
    final dx = to.x - from.x;
    final dy = to.y - from.y;

    for (var i = 1; i <= _waypointCount; i++) {
      final t = i / (_waypointCount + 1);
      // Alternate the bend axis to mimic a street grid rather than a straight
      // line, while staying deterministic for each endpoint pair.
      final bend = math.sin(math.pi * t);
      final alternating = i.isEven ? 1.0 : -1.0;
      final x = from.x + dx * t + bend * dy * 0.18 * alternating;
      final y = from.y + dy * t - bend * dx * 0.18 * alternating;
      points.add(MapPoint(x: x, y: y).clamped);
    }

    points.add(to);
    return List.unmodifiable(points);
  }

  /// Samples a position at normalised progress [t] (0..1) along [route].
  ///
  /// Returns null for an empty route so callers can render an explicit empty
  /// state rather than a misleading marker at the map origin.
  static MapPoint? pointAt(List<MapPoint> route, double t) {
    if (route.isEmpty) return null;
    if (route.length == 1) return route.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (route.length - 1);
    final index = scaled.floor().clamp(0, route.length - 2);
    final localT = scaled - index;
    return MapPoint.lerp(route[index], route[index + 1], localT);
  }
}
