import 'package:flutter/foundation.dart';

/// A schematic point on the illustrated demo map.
///
/// Coordinates are normalised 0..1 fractions of the map canvas, not GPS
/// latitude/longitude. `docs/DATA_MODEL.md` explicitly calls these "schematic
/// coordinates (not GPS)".
@immutable
class MapPoint {
  const MapPoint({required this.x, required this.y});

  final double x;
  final double y;

  /// Clamps the point into the unit square so painters never draw off-canvas.
  MapPoint get clamped => MapPoint(x: x.clamp(0, 1), y: y.clamp(0, 1));

  /// Linear interpolation, used to animate a marker along a route.
  static MapPoint lerp(MapPoint a, MapPoint b, double t) {
    return MapPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t);
  }

  @override
  bool operator ==(Object other) =>
      other is MapPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'MapPoint($x, $y)';
}

/// A demo destination or pickup point from `locations.json`.
@immutable
class Location {
  const Location({
    required this.id,
    required this.name,
    required this.addressLabel,
    required this.category,
    required this.point,
    required this.popularity,
  });

  final String id;
  final String name;

  /// Human-readable demo address label. Never a real address.
  final String addressLabel;

  /// Fixture category: saved, education, shopping, transit, leisure.
  final String category;

  /// Schematic position on the demo map.
  final MapPoint point;

  /// Higher is more popular; drives the "Popular nearby" ordering.
  final int popularity;

  /// The short locality shown after the middle dot in list rows.
  String get locality {
    final parts = addressLabel.split(' · ');
    return parts.length > 1 ? parts.last : addressLabel;
  }

  @override
  bool operator ==(Object other) => other is Location && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Location($id, $name)';
}

/// A ride vehicle category from `vehicles.json`.
///
/// Labels are fictional simulation labels, not a real service offering.
@immutable
class Vehicle {
  const Vehicle({
    required this.id,
    required this.category,
    required this.label,
    required this.capacity,
    required this.baseFare,
    required this.perKmFare,
    required this.estimatedMinutes,
  });

  final String id;
  final String category;
  final String label;
  final int capacity;

  /// Integer rupiah base fare.
  final int baseFare;

  /// Integer rupiah per simulated kilometre.
  final int perKmFare;

  /// Estimated pickup/arrival minutes shown on the option row.
  final int estimatedMinutes;

  @override
  bool operator ==(Object other) => other is Vehicle && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Vehicle($id, $label)';
}

/// A fictional demo driver from `drivers.json`.
@immutable
class Driver {
  const Driver({
    required this.id,
    required this.displayName,
    required this.rating,
    required this.completedDemoTrips,
    required this.vehicleId,
    required this.avatarAsset,
    required this.seedOrder,
  });

  final String id;
  final String displayName;
  final double rating;
  final int completedDemoTrips;

  /// Foreign key into `vehicles.json`.
  final String vehicleId;

  /// Bare filename resolved through the image asset helper.
  final String avatarAsset;

  /// Stable ordering key used by deterministic assignment.
  final int seedOrder;

  @override
  bool operator ==(Object other) => other is Driver && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Driver($id, $displayName)';
}

/// A demo promo code from `promos.json`.
@immutable
class Promo {
  const Promo({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.minimumFare,
    required this.active,
  });

  final String id;
  final String code;
  final String title;

  /// Either `percent` or `fixed`.
  final String discountType;

  /// Percentage points when [isPercent], otherwise integer rupiah off.
  final int discountValue;

  /// Minimum pre-discount fare required for eligibility.
  final int minimumFare;

  final bool active;

  /// Whether this promo takes a percentage off.
  bool get isPercent => discountType == 'percent';

  /// The discount this promo yields for [fare], clamped so a fare never goes
  /// negative and never exceeds the fare itself.
  ///
  /// An inactive promo yields no discount, regardless of the fare.
  int discountFor(int fare) {
    if (!active) return 0;
    if (fare < minimumFare) return 0;
    final raw = isPercent ? (fare * discountValue) ~/ 100 : discountValue;
    return raw.clamp(0, fare);
  }

  /// Whether this promo may be applied to [fare].
  bool eligibleFor(int fare) => active && fare >= minimumFare;

  @override
  bool operator ==(Object other) => other is Promo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Promo($code)';
}

/// A demo restaurant from `restaurants.json`.
@immutable
class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.etaLabel,
    required this.imageAsset,
    required this.featured,
  });

  final String id;
  final String name;
  final String category;
  final double rating;
  final String etaLabel;
  final String imageAsset;
  final bool featured;

  @override
  bool operator ==(Object other) => other is Restaurant && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Restaurant($id, $name)';
}

/// A demo menu item from `menu_items.json`.
@immutable
class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageAsset,
    required this.available,
  });

  final String id;

  /// Foreign key into `restaurants.json`.
  final String restaurantId;

  final String name;
  final String description;
  final int price;
  final String imageAsset;
  final bool available;

  @override
  bool operator ==(Object other) => other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MenuItem($id, $name)';
}

/// A parcel delivery service option from `delivery_options.json`.
@immutable
class DeliveryOption {
  const DeliveryOption({
    required this.id,
    required this.serviceType,
    required this.label,
    required this.baseFee,
    required this.perKmFee,
    required this.etaLabel,
  });

  final String id;
  final String serviceType;
  final String label;
  final int baseFee;
  final int perKmFee;
  final String etaLabel;

  @override
  bool operator ==(Object other) => other is DeliveryOption && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DeliveryOption($id)';
}

/// A demo reward from `rewards.json`.
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.title,
    required this.pointsCost,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final int pointsCost;
  final String description;

  /// Fixture default unlock state at first launch.
  final bool unlocked;

  @override
  bool operator ==(Object other) => other is Reward && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Reward($id, $title)';
}

/// The fictional demo profile from `demo_user.json`.
@immutable
class DemoUser {
  const DemoUser({
    required this.id,
    required this.displayName,
    required this.avatarAsset,
    required this.demoWalletBalance,
    required this.rewardPoints,
    required this.favoriteLocationIds,
    this.isDemo = true,
  });

  final String id;
  final String displayName;
  final String avatarAsset;

  /// Fictional wallet balance in integer rupiah.
  final int demoWalletBalance;

  final int rewardPoints;
  final List<String> favoriteLocationIds;

  /// Always true in this simulator; stored explicitly per the data model.
  final bool isDemo;

  /// First name, used for the home greeting.
  String get firstName => displayName.split(' ').first;

  DemoUser copyWith({
    String? displayName,
    int? demoWalletBalance,
    int? rewardPoints,
    List<String>? favoriteLocationIds,
  }) {
    return DemoUser(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarAsset: avatarAsset,
      demoWalletBalance: demoWalletBalance ?? this.demoWalletBalance,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      favoriteLocationIds: favoriteLocationIds ?? this.favoriteLocationIds,
      isDemo: isDemo,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DemoUser &&
      other.id == id &&
      other.displayName == displayName &&
      other.demoWalletBalance == demoWalletBalance &&
      other.rewardPoints == rewardPoints &&
      listEquals(other.favoriteLocationIds, favoriteLocationIds);

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    demoWalletBalance,
    rewardPoints,
    Object.hashAll(favoriteLocationIds),
  );

  @override
  String toString() => 'DemoUser($id, $displayName)';
}
