/// Product-level constants and honesty labels.
///
/// Every user-visible claim about money, people, or services must carry one of
/// the [DemoCopy] labels so the simulation is never mistaken for a real
/// transportation, delivery, or payment service.
abstract final class AppInfo {
  static const String name = 'GoMotion';
  static const String tagline = 'Move smarter. Feel every journey.';
  static const String version = '0.1.0';

  /// Shown in About GoMotion and settings.
  static const String offlineNotice =
      'Demo simulation — works fully offline. No network, maps, GPS, or '
      'payments are used.';

  /// Seed for deterministic driver and courier assignment.
  ///
  /// Tests override the assigned seed through the fixture repository's ride id,
  /// so this stays a single stable constant in production.
  static const int simulationSeed = SimulationTiming.defaultSeed;
}

/// Reusable honesty labels required by `docs/SECURITY_AND_PRIVACY.md`.
abstract final class DemoCopy {
  static const String pill = 'DEMO';
  static const String map = 'DEMO MAP';
  static const String driver = 'Demo driver';
  static const String plate = 'DEMO';
  static const String wallet = 'Fictional balance';
  static const String transaction = 'Fictional demo transaction';
  static const String fare = 'Estimated demo fare';
  static const String fee = 'Demo fee';
  static const String points = 'demo points';
  static const String simulation = 'A local simulation is in progress';
  static const String arrival = 'Simulated driver arrival';
}

/// Bundled fixture filenames under `assets/data/`.
abstract final class FixtureFiles {
  static const String locations = 'assets/data/locations.json';
  static const String drivers = 'assets/data/drivers.json';
  static const String vehicles = 'assets/data/vehicles.json';
  static const String promos = 'assets/data/promos.json';
  static const String restaurants = 'assets/data/restaurants.json';
  static const String menuItems = 'assets/data/menu_items.json';
  static const String deliveryOptions = 'assets/data/delivery_options.json';
  static const String rewards = 'assets/data/rewards.json';
  static const String demoUser = 'assets/data/demo_user.json';
}

/// Bundled image directory for fixture-referenced assets.
abstract final class ImageAssets {
  static const String directory = 'assets/images/';

  static const String brandMark = '${directory}gomotion_mark.png';
  static const String userAvatar = '${directory}avatar_demo.png';

  /// Resolves a bare fixture filename (e.g. `"nori_house.png"`) to its bundled
  /// asset key. Fixtures store bare filenames, not full paths.
  static String resolve(String fileName) => '$directory$fileName';
}

/// Deterministic simulation tunables.
///
/// Durations are intentionally short so a reviewer can complete every journey
/// without waiting, while still reading as a real progression.
abstract final class SimulationTiming {
  /// Time spent on the radar before a driver is assigned.
  static const Duration matching = Duration(seconds: 4);

  /// Driver approach window before pickup can be confirmed.
  static const Duration driverApproach = Duration(seconds: 8);

  /// Simulated in-ride duration.
  static const Duration rideInProgress = Duration(seconds: 10);

  /// Courier matching window for GoFood and GoSend.
  static const Duration courierMatching = Duration(seconds: 4);

  /// Food preparation window after courier assignment.
  static const Duration preparing = Duration(seconds: 6);

  /// Courier transit window.
  static const Duration inTransit = Duration(seconds: 8);

  /// Default seed when no test seed is injected.
  static const int defaultSeed = 7;

  /// Number of discrete ETA ticks used to animate countdowns.
  static const int etaTicks = 10;
}

/// Currency formatting for fictional demo amounts.
abstract final class Currency {
  static const String symbol = 'Rp';

  /// Formats an integer rupiah amount with dot thousand separators.
  ///
  /// Hand-rolled so no formatting dependency is required and output is stable
  /// across platforms and locales.
  static String format(int amount) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${negative ? '-' : ''}$symbol ${buffer.toString()}';
  }
}
