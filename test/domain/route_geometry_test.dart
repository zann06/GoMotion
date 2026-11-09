import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/domain/entities/fixtures.dart';
import 'package:gomotion/domain/services/route_geometry.dart';

void main() {
  group('RouteGeometry.between', () {
    test('is deterministic for the same endpoints', () {
      const from = MapPoint(x: 0.1, y: 0.2);
      const to = MapPoint(x: 0.85, y: 0.75);

      final a = RouteGeometry.between(from, to);
      final b = RouteGeometry.between(from, to);

      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, closeTo(b[i].x, 1e-9));
        expect(a[i].y, closeTo(b[i].y, 1e-9));
      }
    });

    test('runs from the origin to the destination', () {
      const from = MapPoint(x: 0.1, y: 0.2);
      const to = MapPoint(x: 0.85, y: 0.75);

      final route = RouteGeometry.between(from, to);

      expect(route.first.x, closeTo(from.x, 1e-9));
      expect(route.first.y, closeTo(from.y, 1e-9));
      expect(route.last.x, closeTo(to.x, 1e-9));
      expect(route.last.y, closeTo(to.y, 1e-9));
    });
  });

  group('RouteGeometry.pointAt', () {
    test('returns null for an empty route', () {
      expect(RouteGeometry.pointAt(const [], 0.5), isNull);
    });

    test('returns the only point for a single-point route', () {
      const only = MapPoint(x: 0.3, y: 0.4);
      final point = RouteGeometry.pointAt(const [only], 0.9);
      expect(point!.x, closeTo(only.x, 1e-9));
      expect(point.y, closeTo(only.y, 1e-9));
    });

    test('clamps progress outside the 0..1 range', () {
      const from = MapPoint(x: 0, y: 0);
      const to = MapPoint(x: 1, y: 1);
      final route = RouteGeometry.between(from, to);

      final before = RouteGeometry.pointAt(route, -1)!;
      final after = RouteGeometry.pointAt(route, 2)!;

      expect(before.x, closeTo(from.x, 1e-9));
      expect(after.x, closeTo(to.x, 1e-9));
    });
  });

  group('RouteGeometry.bearingAt', () {
    test('is zero for a degenerate route', () {
      expect(RouteGeometry.bearingAt(const [], 0.5), 0);
      expect(RouteGeometry.bearingAt(const [MapPoint(x: 0.5, y: 0.5)], 0.5), 0);
    });

    test('points east for a left-to-right segment', () {
      const a = MapPoint(x: 0, y: 0.5);
      const b = MapPoint(x: 1, y: 0.5);
      expect(
        RouteGeometry.bearingAt(const [a, b], 0.5),
        closeTo(math.pi / 2, 1e-6),
      );
    });

    test('points south for a top-to-bottom segment', () {
      const a = MapPoint(x: 0.5, y: 0);
      const b = MapPoint(x: 0.5, y: 1);
      expect(
        RouteGeometry.bearingAt(const [a, b], 0.5),
        closeTo(math.pi, 1e-6),
      );
    });

    test('points north for a bottom-to-top segment', () {
      const a = MapPoint(x: 0.5, y: 1);
      const b = MapPoint(x: 0.5, y: 0);
      expect(RouteGeometry.bearingAt(const [a, b], 0.5), closeTo(0, 1e-6));
    });
  });
}
