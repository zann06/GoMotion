import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_failure.dart';
import '../../domain/entities/fixtures.dart';
import '../../domain/repositories/fixture_repository.dart';

/// Loads GoMotion fixtures from bundled assets and validates integrity.
///
/// Parsing is strict: a malformed field is a hard failure surfaced as
/// [FixtureFailure] rather than a silently defaulted value, so a broken dataset
/// can never masquerade as valid demo data.
final class JsonFixtureRepository implements FixtureRepository {
  JsonFixtureRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<FixtureBundle> load() async {
    // No cross-call caching here: `fixtureBundleProvider` already memoises the
    // resolved bundle for the lifetime of its provider container. Keeping this
    // method pure means test containers stay fully isolated from one another.
    final bundle = FixtureBundle(
      locations: await _readList(FixtureFiles.locations, _parseLocation),
      drivers: await _readList(FixtureFiles.drivers, _parseDriver),
      vehicles: await _readList(FixtureFiles.vehicles, _parseVehicle),
      promos: await _readList(FixtureFiles.promos, _parsePromo),
      restaurants: await _readList(FixtureFiles.restaurants, _parseRestaurant),
      menuItems: await _readList(FixtureFiles.menuItems, _parseMenuItem),
      deliveryOptions: await _readList(
        FixtureFiles.deliveryOptions,
        _parseDeliveryOption,
      ),
      rewards: await _readList(FixtureFiles.rewards, _parseReward),
      demoUser: await _readObject(FixtureFiles.demoUser, _parseDemoUser),
    );

    _validate(bundle);
    return bundle;
  }

  Future<List<T>> _readList<T>(
    String asset,
    T Function(Map<String, Object?> json) parse,
  ) async {
    final decoded = await _decode(asset);
    if (decoded is! List<Object?>) {
      throw FixtureFailure(asset: asset, cause: 'Expected a JSON array.');
    }
    return [
      for (final (index, entry) in decoded.indexed)
        _guard(asset, '[$index]', () {
          if (entry is! Map<String, Object?>) {
            throw FixtureFailure(
              asset: asset,
              cause: 'Entry $index is not a JSON object.',
            );
          }
          return parse(entry);
        }),
    ];
  }

  Future<T> _readObject<T>(
    String asset,
    T Function(Map<String, Object?> json) parse,
  ) async {
    final decoded = await _decode(asset);
    if (decoded is! Map<String, Object?>) {
      throw FixtureFailure(asset: asset, cause: 'Expected a JSON object.');
    }
    return _guard(asset, '{}', () => parse(decoded));
  }

  Future<Object?> _decode(String asset) async {
    final String raw;
    try {
      // `cache: false` is deliberate. `rootBundle` is a `CachingAssetBundle`
      // that memoises the *Future* for each asset for the lifetime of the
      // bundle. In `flutter test` a single bundle instance outlives many
      // `WidgetTester`s, so a cached future produced by an earlier
      // `FakeAsync` zone never completes inside a later test's fake clock and
      // the fixture gate would hang. Reading fresh keeps every container — app
      // or test — fully isolated; `fixtureBundleProvider` is what memoises the
      // parsed result in production.
      raw = await _bundle.loadString(asset, cache: false);
    } on FlutterError catch (error) {
      throw FixtureFailure(asset: asset, cause: error.message);
    }
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      throw FixtureFailure(asset: asset, cause: error.message);
    }
  }

  /// Wraps parsing so any cast error becomes a typed [FixtureFailure].
  T _guard<T>(String asset, String where, T Function() parse) {
    try {
      return parse();
    } on FixtureFailure {
      rethrow;
    } on Object catch (error) {
      throw FixtureFailure(asset: asset, cause: '$where: $error');
    }
  }

  /// Enforces the referential integrity rules from `docs/DATA_MODEL.md`.
  void _validate(FixtureBundle bundle) {
    void requireUnique(String asset, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) {
          throw FixtureFailure(asset: asset, cause: 'Duplicate id "$id".');
        }
      }
    }

    requireUnique(FixtureFiles.locations, bundle.locations.map((l) => l.id));
    requireUnique(FixtureFiles.drivers, bundle.drivers.map((d) => d.id));
    requireUnique(FixtureFiles.vehicles, bundle.vehicles.map((v) => v.id));
    requireUnique(FixtureFiles.promos, bundle.promos.map((p) => p.id));
    requireUnique(
      FixtureFiles.restaurants,
      bundle.restaurants.map((r) => r.id),
    );
    requireUnique(FixtureFiles.menuItems, bundle.menuItems.map((m) => m.id));
    requireUnique(
      FixtureFiles.deliveryOptions,
      bundle.deliveryOptions.map((d) => d.id),
    );
    requireUnique(FixtureFiles.rewards, bundle.rewards.map((r) => r.id));

    final vehicleIds = bundle.vehicles.map((v) => v.id).toSet();
    final locationIds = bundle.locations.map((l) => l.id).toSet();
    final restaurantIds = bundle.restaurants.map((r) => r.id).toSet();

    for (final driver in bundle.drivers) {
      if (!vehicleIds.contains(driver.vehicleId)) {
        throw FixtureFailure(
          asset: FixtureFiles.drivers,
          cause:
              'Driver "${driver.id}" references unknown vehicle '
              '"${driver.vehicleId}".',
        );
      }
    }

    for (final item in bundle.menuItems) {
      if (!restaurantIds.contains(item.restaurantId)) {
        throw FixtureFailure(
          asset: FixtureFiles.menuItems,
          cause:
              'Menu item "${item.id}" references unknown restaurant '
              '"${item.restaurantId}".',
        );
      }
    }

    for (final favorite in bundle.demoUser.favoriteLocationIds) {
      if (!locationIds.contains(favorite)) {
        throw FixtureFailure(
          asset: FixtureFiles.demoUser,
          cause: 'Favourite location "$favorite" does not exist.',
        );
      }
    }

    if (bundle.locations.isEmpty) {
      throw const FixtureFailure(
        asset: FixtureFiles.locations,
        cause: 'At least one demo location is required.',
      );
    }
    if (bundle.vehicles.isEmpty) {
      throw const FixtureFailure(
        asset: FixtureFiles.vehicles,
        cause: 'At least one ride vehicle is required.',
      );
    }
  }

  // --- Field parsers -------------------------------------------------------

  Location _parseLocation(Map<String, Object?> json) {
    return Location(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      addressLabel: _str(json, 'address_label'),
      category: _str(json, 'category'),
      point: MapPoint(x: _num(json, 'map_x'), y: _num(json, 'map_y')).clamped,
      popularity: _int(json, 'popularity'),
    );
  }

  Driver _parseDriver(Map<String, Object?> json) {
    return Driver(
      id: _str(json, 'id'),
      displayName: _str(json, 'display_name'),
      rating: _num(json, 'rating'),
      completedDemoTrips: _int(json, 'completed_demo_trips'),
      vehicleId: _str(json, 'vehicle_id'),
      avatarAsset: _str(json, 'avatar_asset'),
      seedOrder: _int(json, 'seed_order'),
    );
  }

  Vehicle _parseVehicle(Map<String, Object?> json) {
    return Vehicle(
      id: _str(json, 'id'),
      category: _str(json, 'category'),
      label: _str(json, 'label'),
      capacity: _int(json, 'capacity'),
      baseFare: _int(json, 'base_fare'),
      perKmFare: _int(json, 'per_km_fare'),
      estimatedMinutes: _int(json, 'estimated_minutes'),
    );
  }

  Promo _parsePromo(Map<String, Object?> json) {
    return Promo(
      id: _str(json, 'id'),
      code: _str(json, 'code'),
      title: _str(json, 'title'),
      discountType: _str(json, 'discount_type'),
      discountValue: _int(json, 'discount_value'),
      minimumFare: _int(json, 'minimum_fare'),
      active: _bool(json, 'active'),
    );
  }

  Restaurant _parseRestaurant(Map<String, Object?> json) {
    return Restaurant(
      id: _str(json, 'id'),
      name: _str(json, 'name'),
      category: _str(json, 'category'),
      rating: _num(json, 'rating'),
      etaLabel: _str(json, 'eta_label'),
      imageAsset: _str(json, 'image_asset'),
      featured: _bool(json, 'featured'),
    );
  }

  MenuItem _parseMenuItem(Map<String, Object?> json) {
    return MenuItem(
      id: _str(json, 'id'),
      restaurantId: _str(json, 'restaurant_id'),
      name: _str(json, 'name'),
      description: _str(json, 'description'),
      price: _int(json, 'price'),
      imageAsset: _str(json, 'image_asset'),
      available: _bool(json, 'available'),
    );
  }

  DeliveryOption _parseDeliveryOption(Map<String, Object?> json) {
    return DeliveryOption(
      id: _str(json, 'id'),
      serviceType: _str(json, 'service_type'),
      label: _str(json, 'label'),
      baseFee: _int(json, 'base_fee'),
      perKmFee: _int(json, 'per_km_fee'),
      etaLabel: _str(json, 'eta_label'),
    );
  }

  Reward _parseReward(Map<String, Object?> json) {
    return Reward(
      id: _str(json, 'id'),
      title: _str(json, 'title'),
      pointsCost: _int(json, 'points_cost'),
      description: _str(json, 'description'),
      unlocked: _bool(json, 'unlocked'),
    );
  }

  DemoUser _parseDemoUser(Map<String, Object?> json) {
    return DemoUser(
      id: _str(json, 'id'),
      displayName: _str(json, 'display_name'),
      avatarAsset: _str(json, 'avatar_asset'),
      demoWalletBalance: _int(json, 'demo_wallet_balance'),
      rewardPoints: _int(json, 'reward_points'),
      favoriteLocationIds: _strList(json, 'favorite_location_ids'),
      isDemo: json['is_demo'] is bool ? json['is_demo']! as bool : true,
    );
  }

  String _str(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FixtureFailure(
        asset: key,
        cause: 'Expected non-empty string "$key".',
      );
    }
    return value;
  }

  int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FixtureFailure(asset: key, cause: 'Expected number "$key".');
  }

  double _num(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FixtureFailure(asset: key, cause: 'Expected number "$key".');
  }

  bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FixtureFailure(asset: key, cause: 'Expected boolean "$key".');
  }

  List<String> _strList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List<Object?>) {
      throw FixtureFailure(asset: key, cause: 'Expected string array "$key".');
    }
    return value
        .map((e) {
          if (e is! String) {
            throw FixtureFailure(
              asset: key,
              cause: 'Expected strings inside "$key".',
            );
          }
          return e;
        })
        .toList(growable: false);
  }
}
