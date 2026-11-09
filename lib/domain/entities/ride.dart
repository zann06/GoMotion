import 'package:flutter/foundation.dart';

import 'fixtures.dart';

/// The ride lifecycle from `docs/SIMULATION_ENGINE.md`:
/// `IDLE → SELECTING → SEARCHING → DRIVER_ASSIGNED → DRIVER_ARRIVING →
/// IN_PROGRESS → COMPLETED → PAID → RATED`.
enum RideStage {
  /// Nothing selected yet.
  idle,

  /// Pickup and destination chosen; vehicle options are being compared.
  selecting,

  /// Booking confirmed, radar search running.
  searching,

  /// A driver has been assigned but has not started moving.
  driverAssigned,

  /// The assigned driver is approaching the pickup point.
  driverArriving,

  /// The passenger is on board and the trip is running.
  inProgress,

  /// The trip finished; payment is outstanding.
  completed,

  /// Payment committed.
  paid,

  /// Rating submitted; the terminal state.
  rated;

  /// Whether the ride may still be cancelled.
  ///
  /// Cancellation is permitted through [driverArriving]. Cancelling during
  /// [inProgress] is disabled in this demo, per the specification's default.
  bool get isCancellable =>
      this == selecting ||
      this == searching ||
      this == driverAssigned ||
      this == driverArriving;

  /// Whether the ride has produced a terminal outcome.
  bool get isTerminal => this == rated;

  /// Whether a payment may be attempted.
  bool get isPayable => this == completed;

  /// Whether a rating may be submitted.
  bool get isRatable => this == paid;

  /// Whether the simulation should still be ticking.
  bool get isLive =>
      this == searching ||
      this == driverAssigned ||
      this == driverArriving ||
      this == inProgress;
}

/// The explicit stage ordering, used to validate transitions.
const List<RideStage> _rideOrder = [
  RideStage.idle,
  RideStage.selecting,
  RideStage.searching,
  RideStage.driverAssigned,
  RideStage.driverArriving,
  RideStage.inProgress,
  RideStage.completed,
  RideStage.paid,
  RideStage.rated,
];

/// A simulated ride draft and its lifecycle state.
///
/// Immutable: every change produces a new instance, so providers can compare by
/// value and widgets never observe a partially mutated ride.
@immutable
class Ride {
  const Ride({
    required this.id,
    required this.stage,
    required this.pickup,
    required this.destination,
    this.vehicle,
    this.fare,
    this.driverId,
    this.promoCode,
    this.progress = 0,
    this.paymentMethod,
    this.rating,
    this.generation = 0,
  });

  /// Stable identifier, also the seed for deterministic driver assignment.
  final String id;

  final RideStage stage;
  final Location pickup;
  final Location destination;

  /// The chosen vehicle category, null while still selecting.
  final Vehicle? vehicle;

  /// The computed fare, null until a vehicle is chosen.
  final FareQuote? fare;

  /// Assigned driver id, resolved through the fixture bundle.
  final String? driverId;

  /// Applied promo code, if any.
  final String? promoCode;

  /// Simulated progress 0..1 along the route.
  final double progress;

  /// How the ride was settled.
  final String? paymentMethod;

  /// Submitted star rating, 1..5.
  final int? rating;

  /// Guard token. Events carrying a stale generation are ignored.
  final int generation;

  /// Simulated distance in kilometres.
  double get distanceKm => fare?.distanceKm ?? 0;

  /// The fare total, or 0 before a vehicle is chosen.
  int get total => fare?.total ?? 0;

  /// Whether the ride can be cancelled right now.
  bool get isCancellable => stage.isCancellable;

  Ride copyWith({
    String? id,
    RideStage? stage,
    Location? pickup,
    Location? destination,
    Vehicle? vehicle,
    FareQuote? fare,
    String? driverId,
    String? promoCode,
    double? progress,
    String? paymentMethod,
    int? rating,
    int? generation,
    bool clearDriver = false,
    bool clearPromo = false,
  }) {
    return Ride(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      vehicle: vehicle ?? this.vehicle,
      fare: fare ?? this.fare,
      driverId: clearDriver ? null : (driverId ?? this.driverId),
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      progress: progress ?? this.progress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rating: rating ?? this.rating,
      generation: generation ?? this.generation,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Ride &&
      other.id == id &&
      other.stage == stage &&
      other.pickup == pickup &&
      other.destination == destination &&
      other.vehicle == vehicle &&
      other.fare == fare &&
      other.driverId == driverId &&
      other.promoCode == promoCode &&
      other.progress == progress &&
      other.paymentMethod == paymentMethod &&
      other.rating == rating &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(
    id,
    stage,
    pickup,
    destination,
    vehicle,
    fare,
    driverId,
    promoCode,
    progress,
    paymentMethod,
    rating,
    generation,
  );

  @override
  String toString() => 'Ride($id, $stage, progress: $progress)';
}

/// The result of quoting a vehicle for a trip.
@immutable
class FareQuote {
  const FareQuote({
    required this.baseFare,
    required this.distanceFare,
    required this.distanceKm,
    required this.discount,
    this.promoCode,
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
      other is FareQuote &&
      other.baseFare == baseFare &&
      other.distanceFare == distanceFare &&
      other.distanceKm == distanceKm &&
      other.discount == discount &&
      other.promoCode == promoCode;

  @override
  int get hashCode =>
      Object.hash(baseFare, distanceFare, distanceKm, discount, promoCode);

  @override
  String toString() => 'FareQuote(total: $total, km: $distanceKm)';
}

/// Whether [from] may legally advance to [to].
///
/// The forward path is strictly sequential; the only backwards move allowed is
/// clearing back to [RideStage.idle] via cancellation or reset, which is handled
/// by the notifier rather than as a normal transition.
bool isValidRideTransition(RideStage from, RideStage to) {
  if (from == to) return false;
  final fromIndex = _rideOrder.indexOf(from);
  final toIndex = _rideOrder.indexOf(to);
  if (fromIndex < 0 || toIndex < 0) return false;
  return toIndex == fromIndex + 1;
}
