import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/entities/fixtures.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';
import 'package:gomotion/domain/services/fare_engine.dart';
import 'package:gomotion/domain/services/route_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FixtureBundle bundle;

  setUpAll(() async {
    bundle = await JsonFixtureRepository().load();
  });

  group('FareEngine.distanceKm', () {
    test('is deterministic for the same endpoints', () {
      const a = MapPoint(x: 0.1, y: 0.2);
      const b = MapPoint(x: 0.8, y: 0.7);

      expect(FareEngine.distanceKm(a, b), FareEngine.distanceKm(a, b));
    });

    test('never returns zero for distinct points', () {
      const a = MapPoint(x: 0.5, y: 0.5);
      const b = MapPoint(x: 0.5001, y: 0.5);

      expect(FareEngine.distanceKm(a, b), greaterThan(0));
    });

    test('clamps to the documented 1..12 km band', () {
      const a = MapPoint(x: 0, y: 0);
      const b = MapPoint(x: 1, y: 1);

      final distance = FareEngine.distanceKm(a, b);
      expect(distance, inInclusiveRange(1.0, 12.0));
    });

    test('is symmetric', () {
      const a = MapPoint(x: 0.2, y: 0.3);
      const b = MapPoint(x: 0.7, y: 0.9);

      expect(
        FareEngine.distanceKm(a, b),
        closeTo(FareEngine.distanceKm(b, a), 0.0001),
      );
    });
  });

  group('FareEngine.quote', () {
    late Vehicle vehicle;

    setUp(() {
      vehicle = bundle.vehicles.firstWhere((v) => v.id == 'veh_car');
    });

    test('adds base fare to per-km fare', () {
      final quote = FareEngine.quote(vehicle: vehicle, distanceKm: 5);

      expect(quote.baseFare, vehicle.baseFare);
      expect(quote.distanceFare, (vehicle.perKmFare * 5).round());
      expect(quote.total, vehicle.baseFare + vehicle.perKmFare * 5);
      expect(quote.discount, 0);
    });

    test('applies a percent promo', () {
      const promo = Promo(
        id: 'p',
        code: 'TEN',
        title: '10% off',
        discountType: 'percent',
        discountValue: 10,
        minimumFare: 0,
        active: true,
      );

      final quote = FareEngine.quote(
        vehicle: vehicle,
        distanceKm: 5,
        promo: promo,
      );

      expect(quote.discount, quote.subtotal ~/ 10);
      expect(quote.total, quote.subtotal - quote.discount);
      expect(quote.promoCode, 'TEN');
    });

    test('applies a fixed promo', () {
      const promo = Promo(
        id: 'p',
        code: 'FLAT',
        title: 'Flat 5k',
        discountType: 'fixed',
        discountValue: 5000,
        minimumFare: 0,
        active: true,
      );

      final quote = FareEngine.quote(
        vehicle: vehicle,
        distanceKm: 1,
        promo: promo,
      );

      expect(quote.discount, 5000);
    });

    test('ignores a promo below its minimum fare', () {
      const promo = Promo(
        id: 'p',
        code: 'BIG',
        title: 'Needs big spend',
        discountType: 'fixed',
        discountValue: 5000,
        minimumFare: 10_000_000,
        active: true,
      );

      final quote = FareEngine.quote(
        vehicle: vehicle,
        distanceKm: 2,
        promo: promo,
      );

      expect(quote.discount, 0);
      expect(quote.promoCode, isNull);
    });

    test('never produces a negative total', () {
      const promo = Promo(
        id: 'p',
        code: 'HUGE',
        title: 'Oversized discount',
        discountType: 'fixed',
        discountValue: 9_999_999,
        minimumFare: 0,
        active: true,
      );

      final quote = FareEngine.quote(
        vehicle: vehicle,
        distanceKm: 1,
        promo: promo,
      );

      expect(quote.total, 0);
      expect(quote.total, greaterThanOrEqualTo(0));
    });
  });

  group('Promo rules', () {
    test('inactive promos yield no discount', () {
      const promo = Promo(
        id: 'p',
        code: 'OFF',
        title: 'Inactive',
        discountType: 'percent',
        discountValue: 50,
        minimumFare: 0,
        active: false,
      );

      expect(promo.discountFor(100_000), 0);
      expect(promo.eligibleFor(100_000), isFalse);
    });

    test('fixture promos have sane values', () {
      for (final promo in bundle.promos) {
        expect(promo.discountValue, greaterThan(0));
        expect(promo.minimumFare, greaterThanOrEqualTo(0));
        expect(promo.isPercent, anyOf(isTrue, isFalse));
      }
    });
  });

  group('RouteGeometry', () {
    test('produces a deterministic polyline between endpoints', () {
      const a = MapPoint(x: 0.18, y: 0.72);
      const b = MapPoint(x: 0.72, y: 0.28);

      final first = RouteGeometry.between(a, b);
      final second = RouteGeometry.between(a, b);

      expect(first, second);
      expect(first.first, a);
      expect(first.last, b);
      expect(first.length, greaterThan(2));
    });

    test('keeps every waypoint inside the unit square', () {
      const a = MapPoint(x: 0, y: 0);
      const b = MapPoint(x: 1, y: 1);

      for (final point in RouteGeometry.between(a, b)) {
        expect(point.x, inInclusiveRange(0, 1));
        expect(point.y, inInclusiveRange(0, 1));
      }
    });

    test('pointAt interpolates progress', () {
      const a = MapPoint(x: 0, y: 0);
      const b = MapPoint(x: 1, y: 0);
      final route = [a, b];

      expect(RouteGeometry.pointAt(route, 0), a);
      expect(RouteGeometry.pointAt(route, 1), b);

      final mid = RouteGeometry.pointAt(route, 0.5);
      expect(mid, isNotNull);
      expect(mid!.x, closeTo(0.5, 0.0001));
    });

    test('pointAt returns null for an empty route', () {
      expect(RouteGeometry.pointAt(const [], 0.5), isNull);
    });

    test('pointAt clamps progress outside 0..1', () {
      const a = MapPoint(x: 0, y: 0);
      const b = MapPoint(x: 1, y: 1);

      expect(RouteGeometry.pointAt([a, b], -1), a);
      expect(RouteGeometry.pointAt([a, b], 2), b);
    });
  });
}
