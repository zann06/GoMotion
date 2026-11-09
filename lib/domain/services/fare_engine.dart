import 'dart:math' as math;

import '../entities/fixtures.dart';
import '../entities/ride.dart';

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
  static FareQuote quote({
    required Vehicle vehicle,
    required double distanceKm,
    Promo? promo,
  }) {
    final distanceFare = (vehicle.perKmFare * distanceKm).round();
    final subtotal = vehicle.baseFare + distanceFare;
    final discount = promo == null ? 0 : promo.discountFor(subtotal);
    return FareQuote(
      baseFare: vehicle.baseFare,
      distanceFare: distanceFare,
      distanceKm: distanceKm,
      discount: discount,
      promoCode: discount > 0 ? promo?.code : null,
    );
  }
}
