import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../entities/fixtures.dart';

/// A computed fare breakdown for a simulated ride.
@immutable
class FareBreakdown {
  const FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.distanceKm,
    required this.discount,
    required this.promoCode,
  });

  final int baseFare;
  final int distanceFare;
  final double distanceKm;
  final int discount;
  final String? promoCode;

  /// Fare before any promo discount.
  int get subtotal => baseFare + distanceFare;

  /// Fare after discount, never negative.
  int get total => (subtotal - discount).clamp(0, subtotal);

  @override
  bool operator ==(Object other) =>
      other is FareBreakdown &&
      other.baseFare == baseFare &&
      other.distanceFare == distanceFare &&
      other.distanceKm == distanceKm &&
      other.discount == discount &&
      other.promoCode == promoCode;

  @override
  int get hashCode =>
      Object.hash(baseFare, distanceFare, distanceKm, discount, promoCode);

  @override
  String toString() =>
      'FareBreakdown(total: $total, discount: $discount, promo: $promoCode)';
}

/// The ride fare engine.
///
/// Pure functions with no I/O so the rules are directly unit-testable and the UI
/// never computes money itself.
abstract final class FareEngine {
  /// Scale factor turning normalised map distance into a believable kilometre
  /// band for the small demo city. There is no routing service; the UI labels
  /// this as an estimate.
  static const double _kmScale = 14;

  /// Floor so a very short demo hop never shows a zero distance.
  static const double _minKm = 1;

  /// Ceiling so a cross-map hop stays plausible.
  static const double _maxKm = 12;

  /// Returns the simulated distance in kilometres, rounded to one decimal.
  static double distanceKm(MapPoint from, MapPoint to) {
    final dx = (to.x - from.x) * _kmScale;
    final dy = (to.y - from.y) * _kmScale;
    final raw = math.sqrt(dx * dx + dy * dy);
    final clamped = raw.clamp(_minKm, _maxKm);
    return (clamped * 10).roundToDouble() / 10;
  }

  /// Computes the fare for [vehicle] travelling [distanceKm].
  ///
  /// When [promo] is supplied and eligible, its discount is applied. An
  /// ineligible promo contributes no discount rather than throwing, because the
  /// review screen shows drafts optimistically.
  static FareBreakdown quote({
    required Vehicle vehicle,
    required double distanceKm,
    Promo? promo,
  }) {
    final distanceFare = (vehicle.perKmFare * distanceKm).round();
    final subtotal = vehicle.baseFare + distanceFare;
    final discount = promo == null ? 0 : promo.discountFor(subtotal);
    return FareBreakdown(
      baseFare: vehicle.baseFare,
      distanceFare: distanceFare,
      distanceKm: distanceKm,
      discount: discount,
      promoCode: discount > 0 ? promo?.code : null,
    );
  }
}
