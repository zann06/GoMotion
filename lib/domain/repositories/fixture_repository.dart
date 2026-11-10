import '../entities/fixtures.dart';
import '../entities/inbox_message.dart';

/// Read-only access to the bundled, immutable demo dataset.
///
/// This is the domain contract. The JSON implementation lives in `lib/data/`,
/// which keeps the domain layer free of Flutter asset dependencies.
abstract interface class FixtureRepository {
  /// Loads and validates every fixture.
  ///
  /// Throws [FixtureFailure] when the bundles are missing, malformed, or fail
  /// referential integrity checks. Callers surface a recoverable error state.
  Future<FixtureBundle> load();
}

/// An immutable, integrity-checked snapshot of the whole demo dataset.
///
/// Constructing this through the loader guarantees foreign keys resolve, so
/// application code may look entities up without defensive null handling.
final class FixtureBundle {
  FixtureBundle({
    required this.locations,
    required this.drivers,
    required this.vehicles,
    required this.promos,
    required this.restaurants,
    required this.menuItems,
    required this.deliveryOptions,
    required this.rewards,
    required this.notifications,
    required this.demoUser,
  });

  final List<Location> locations;
  final List<Driver> drivers;
  final List<Vehicle> vehicles;
  final List<Promo> promos;
  final List<Restaurant> restaurants;
  final List<MenuItem> menuItems;
  final List<DeliveryOption> deliveryOptions;
  final List<Reward> rewards;

  /// Seeded inbox messages, newest first as authored in the fixture.
  final List<InboxMessage> notifications;

  final DemoUser demoUser;

  late final Map<String, Location> _locationsById = {
    for (final l in locations) l.id: l,
  };
  late final Map<String, Driver> _driversById = {
    for (final d in drivers) d.id: d,
  };
  late final Map<String, Vehicle> _vehiclesById = {
    for (final v in vehicles) v.id: v,
  };
  late final Map<String, Promo> _promosByCode = {
    for (final p in promos) p.code.toUpperCase(): p,
  };
  late final Map<String, Restaurant> _restaurantsById = {
    for (final r in restaurants) r.id: r,
  };
  late final Map<String, MenuItem> _menuById = {
    for (final m in menuItems) m.id: m,
  };
  late final Map<String, DeliveryOption> _deliveryById = {
    for (final d in deliveryOptions) d.id: d,
  };

  /// Looks up a location, or null when the id is unknown.
  Location? location(String id) => _locationsById[id];

  /// Looks up a driver, or null when the id is unknown.
  Driver? driver(String id) => _driversById[id];

  /// Looks up a vehicle, or null when the id is unknown.
  Vehicle? vehicle(String id) => _vehiclesById[id];

  /// Looks up a restaurant, or null when the id is unknown.
  Restaurant? restaurant(String id) => _restaurantsById[id];

  /// Looks up a menu item, or null when the id is unknown.
  MenuItem? menuItem(String id) => _menuById[id];

  /// Looks up a delivery option, or null when the id is unknown.
  DeliveryOption? deliveryOption(String id) => _deliveryById[id];

  /// Looks up an active promo by its user-entered code (case-insensitive).
  Promo? promoByCode(String code) => _promosByCode[code.trim().toUpperCase()];

  /// The driver associated with a vehicle category, used when a ride is
  /// assigned. Deterministic because fixture order is stable.
  Driver? driverForVehicle(String vehicleId) {
    for (final driver in drivers) {
      if (driver.vehicleId == vehicleId) return driver;
    }
    return null;
  }

  /// Menu items belonging to [restaurantId], preserving fixture order.
  List<MenuItem> menuFor(String restaurantId) => [
    for (final item in menuItems)
      if (item.restaurantId == restaurantId) item,
  ];

  /// Locations ordered by popularity, most popular first.
  List<Location> get popularLocations {
    final sorted = [...locations]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    return sorted;
  }

  /// The default pickup location, preferring the saved "home" fixture.
  Location get defaultPickup {
    for (final l in locations) {
      if (l.id == 'loc_home') return l;
    }
    return locations.first;
  }
}
