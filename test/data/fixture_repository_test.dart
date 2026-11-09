import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/core/errors/app_failure.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonFixtureRepository', () {
    late FixtureRepository repository;

    setUp(() {
      repository = JsonFixtureRepository();
    });

    test('loads every bundled fixture', () async {
      final bundle = await repository.load();

      expect(bundle.locations, isNotEmpty);
      expect(bundle.drivers, isNotEmpty);
      expect(bundle.vehicles, isNotEmpty);
      expect(bundle.promos, isNotEmpty);
      expect(bundle.restaurants, isNotEmpty);
      expect(bundle.menuItems, isNotEmpty);
      expect(bundle.deliveryOptions, isNotEmpty);
      expect(bundle.rewards, isNotEmpty);
      expect(bundle.demoUser.id, 'user_demo');
    });

    test('parses location map coordinates into the unit square', () async {
      final bundle = await repository.load();

      for (final location in bundle.locations) {
        expect(location.point.x, inInclusiveRange(0, 1));
        expect(location.point.y, inInclusiveRange(0, 1));
        expect(location.name, isNotEmpty);
        expect(location.addressLabel, isNotEmpty);
      }
    });

    test('parses vehicles with integer fares', () async {
      final bundle = await repository.load();

      for (final vehicle in bundle.vehicles) {
        expect(vehicle.baseFare, greaterThan(0));
        expect(vehicle.perKmFare, greaterThan(0));
        expect(vehicle.capacity, greaterThan(0));
      }
    });

    test('resolves foreign keys for drivers and menu items', () async {
      final bundle = await repository.load();

      for (final driver in bundle.drivers) {
        expect(
          bundle.vehicle(driver.vehicleId),
          isNotNull,
          reason: 'Driver ${driver.id} must reference a known vehicle.',
        );
      }
      for (final item in bundle.menuItems) {
        expect(
          bundle.restaurant(item.restaurantId),
          isNotNull,
          reason: 'Menu item ${item.id} must reference a known restaurant.',
        );
      }
      for (final favorite in bundle.demoUser.favoriteLocationIds) {
        expect(bundle.location(favorite), isNotNull);
      }
    });

    test('menuFor groups items by restaurant', () async {
      final bundle = await repository.load();

      final noriMenu = bundle.menuFor('rest_nori');
      expect(noriMenu, isNotEmpty);
      expect(noriMenu.every((m) => m.restaurantId == 'rest_nori'), isTrue);
    });

    test('popularLocations is ordered by popularity descending', () async {
      final bundle = await repository.load();

      final popular = bundle.popularLocations;
      for (var i = 1; i < popular.length; i++) {
        expect(
          popular[i - 1].popularity,
          greaterThanOrEqualTo(popular[i].popularity),
        );
      }
    });

    test('promo lookup is case-insensitive', () async {
      final bundle = await repository.load();

      expect(bundle.promoByCode('move10'), isNotNull);
      expect(bundle.promoByCode('  MOVE10  '), isNotNull);
      expect(bundle.promoByCode('does-not-exist'), isNull);
    });

    test('defaultPickup prefers the saved home fixture', () async {
      final bundle = await repository.load();

      expect(bundle.defaultPickup.id, 'loc_home');
    });

    test('is repeatable and yields equal data on each load', () async {
      final first = await repository.load();
      final second = await repository.load();

      expect(first.locations.length, second.locations.length);
      expect(first.demoUser.id, second.demoUser.id);
    });
  });

  group('JsonFixtureRepository strictness', () {
    /// A bundle that serves [raw] for any asset key.
    AssetBundle bundleServing(String raw) => _FakeBundle((key) async => raw);

    test('rejects malformed JSON with a typed failure', () async {
      final broken = JsonFixtureRepository(bundle: bundleServing('{not json'));

      await expectLater(
        broken.load(),
        throwsA(
          isA<FixtureFailure>().having(
            (f) => f.code,
            'code',
            'fixture_invalid',
          ),
        ),
      );
    });

    test('rejects a JSON array where an object is required', () async {
      final broken = JsonFixtureRepository(bundle: bundleServing('[]'));

      await expectLater(broken.load(), throwsA(isA<FixtureFailure>()));
    });

    test('rejects entries that are missing required fields', () async {
      final broken = JsonFixtureRepository(bundle: bundleServing('[{}]'));

      await expectLater(
        broken.load(),
        throwsA(
          isA<FixtureFailure>().having((f) => f.cause, 'cause', isNotNull),
        ),
      );
    });
  });
}

/// Serves fixed content so strictness can be tested without altering assets.
final class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._loader);

  final Future<String> Function(String key) _loader;

  @override
  Future<ByteData> load(String key) async {
    final raw = await _loader(key);
    final bytes = utf8.encode(raw);
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
