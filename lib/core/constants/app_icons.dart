import 'package:flutter/material.dart';

import 'mascot_assets.dart';

/// The simulated vehicle shapes used across the ride flow and the schematic map.
///
/// Kept separate from the fixture entity so widgets and the map painter can share
/// one canonical icon mapping without importing the domain layer.
enum VehicleKind {
  /// Single-seat two-wheeler, the cheapest demo option.
  motorbike,

  /// Standard four-seat car.
  car,

  /// Four-seat premium car.
  premium;

  /// Rounded icon that represents this vehicle.
  IconData get icon => switch (this) {
    VehicleKind.motorbike => Icons.two_wheeler_rounded,
    VehicleKind.car => Icons.directions_car_filled_rounded,
    VehicleKind.premium => Icons.local_taxi_rounded,
  };

  /// Accessible label used on the map marker.
  String get label => switch (this) {
    VehicleKind.motorbike => 'demo motorbike',
    VehicleKind.car => 'demo car',
    VehicleKind.premium => 'demo premium car',
  };

  /// The mascot pose that matches this vehicle.
  ///
  /// The mascot rides two-wheelers and drives cars, so the marker on the map is
  /// the character rather than a bare vehicle glyph.
  MascotVariant get mascotVariant => switch (this) {
    VehicleKind.motorbike => MascotVariant.ride,
    VehicleKind.car => MascotVariant.car,
    VehicleKind.premium => MascotVariant.car,
  };

  /// Maps a fixture vehicle category (`GoRide`, `GoCar`, `GoCar Premium`) to a
  /// shape. Unknown or empty categories fall back to a car so the map always
  /// renders something sensible.
  static VehicleKind fromCategory(String? category) {
    final normalised = (category ?? '').toLowerCase();
    if (normalised.contains('premium')) return VehicleKind.premium;
    if (normalised.contains('ride') || normalised.contains('bike')) {
      return VehicleKind.motorbike;
    }
    return VehicleKind.car;
  }
}

/// One canonical set of icons for services and vehicles.
///
/// Centralising these keeps the home shortcuts, active-journey banner, vehicle
/// picker, and map marker visually consistent.
abstract final class AppIcons {
  static const IconData home = Icons.home_rounded;
  static const IconData activity = Icons.receipt_long_rounded;
  static const IconData rewards = Icons.workspace_premium_rounded;
  static const IconData profile = Icons.person_rounded;

  static const IconData ride = Icons.two_wheeler_rounded;
  static const IconData food = Icons.restaurant_rounded;
  static const IconData send = Icons.inventory_2_rounded;

  static const IconData pickup = Icons.trip_origin_rounded;
  static const IconData destination = Icons.place_rounded;
  static const IconData search = Icons.search_rounded;

  /// Resolves a fixture category to its vehicle icon.
  static IconData vehicleFor(String? category) =>
      VehicleKind.fromCategory(category).icon;
}
