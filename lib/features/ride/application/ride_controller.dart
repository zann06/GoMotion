import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/activity_record.dart';
import '../../../domain/entities/fixtures.dart';
import '../../../domain/entities/ride.dart';
import '../../../domain/repositories/fixture_repository.dart';
import '../../../domain/services/fare_engine.dart';
import '../../../simulation/driver_assigner.dart';
import '../../../simulation/simulation_clock.dart';
import '../../activity/application/activity_controller.dart';
import '../../profile/application/profile_controller.dart';

/// Immutable snapshot of the ride flow.
///
/// [generation] is bumped on every start, cancel, and reset. Scheduled callbacks
/// capture the generation they were created under and are discarded when it no
/// longer matches, which is what makes cancellation and reset leave no stale
/// progression behind.
class RideState {
  const RideState({this.ride, this.generation = 0});

  /// The active ride, or null when no flow is in progress.
  final Ride? ride;

  final int generation;

  /// Whether a ride exists at all.
  bool get hasRide => ride != null;

  /// The current stage, defaulting to [RideStage.idle].
  RideStage get stage => ride?.stage ?? RideStage.idle;

  @override
  bool operator ==(Object other) =>
      other is RideState &&
      other.ride == ride &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(ride, generation);
}

/// Drives the simulated ride lifecycle.
///
/// All timing goes through the injected [SimulationClock]; nothing here calls
/// `Future.delayed`. Every mutation is idempotent and guarded, so a double tap
/// or a stale timer can never advance the ride twice.
class RideController extends Notifier<RideState> {
  CancelTask? _pending;

  @override
  RideState build() {
    ref.onDispose(_cancelPending);
    return const RideState();
  }

  FixtureBundle get _bundle {
    final async = ref.read(fixtureBundleProvider);
    final bundle = async.value;
    if (bundle == null) {
      throw StateError('Ride flow requires loaded fixtures.');
    }
    return bundle;
  }

  SimulationClock get _clock => ref.read(simulationClockProvider);

  int get _seed => AppInfo.simulationSeed;

  void _cancelPending() {
    _pending?.call();
    _pending = null;
  }

  /// Invalidate in-flight callbacks and clear any pending timer.
  int _bump() {
    _cancelPending();
    return state.generation + 1;
  }

  /// Begins a new draft with the given endpoints.
  ///
  /// Called by destination selection. Any previous ride is discarded first, so
  /// there is never more than one active ride.
  void beginDraft({required Location pickup, required Location destination}) {
    if (pickup.id == destination.id) return;
    final generation = _bump();
    state = RideState(
      generation: generation,
      ride: Ride(
        id: 'ride_${DateTime.now().microsecondsSinceEpoch}',
        stage: RideStage.selecting,
        pickup: pickup,
        destination: destination,
        generation: generation,
      ),
    );
  }

  /// Chooses a vehicle category and quotes the fare.
  ///
  /// Choosing a different vehicle replaces the existing quote, so the review
  /// total always matches the selected card.
  void selectVehicle(Vehicle vehicle, {Promo? promo}) {
    final ride = state.ride;
    if (ride == null) return;

    final distance = FareEngine.distanceKm(
      ride.pickup.point,
      ride.destination.point,
    );
    final quote = FareEngine.quote(
      vehicle: vehicle,
      distanceKm: distance,
      promo: promo,
    );

    state = RideState(
      generation: state.generation,
      ride: ride.copyWith(
        stage: RideStage.selecting,
        vehicle: vehicle,
        fare: quote,
        promoCode: quote.promoCode,
        // Switching to a vehicle without an applied promo must drop the old
        // code, otherwise the review badge outlives the discount.
        clearPromo: quote.promoCode == null,
      ),
    );
  }

  /// Applies [code] to the current draft, returning a typed failure when it
  /// cannot be applied. Never throws to the UI.
  AppFailure? applyPromoCode(String code) {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');

    final bundle = _bundle;
    final promo = bundle.promoByCode(code);
    if (promo == null) return const InvalidPromoFailure.notFound();
    if (!promo.active) return const InvalidPromoFailure.inactive();

    final vehicle = ride.vehicle;
    if (vehicle == null) return const InvalidPromoFailure.minimumNotMet();

    final distance = FareEngine.distanceKm(
      ride.pickup.point,
      ride.destination.point,
    );
    final subtotal = FareEngine.quote(
      vehicle: vehicle,
      distanceKm: distance,
    ).subtotal;

    if (!promo.eligibleFor(subtotal)) {
      return const InvalidPromoFailure.minimumNotMet();
    }

    selectVehicle(vehicle, promo: promo);
    return null;
  }

  /// Removes any applied promo, restoring the undiscounted fare.
  void clearPromo() {
    final ride = state.ride;
    final vehicle = ride?.vehicle;
    if (ride == null || vehicle == null) return;
    selectVehicle(vehicle);
  }

  /// Confirms the booking and starts the radar search.
  ///
  /// Returns a duplicate failure when a booking is already live, satisfying the
  /// "one booking confirmation per ride" invariant.
  AppFailure? confirmBooking() {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');
    if (ride.vehicle == null) return const NotFoundFailure(id: 'vehicle');

    if (ride.stage != RideStage.selecting) {
      return const DuplicateActionFailure.booking();
    }

    final generation = _bump();
    state = RideState(
      generation: generation,
      ride: ride.copyWith(
        stage: RideStage.searching,
        progress: 0,
        generation: generation,
      ),
    );

    _schedule(SimulationTiming.matching, () => _assignDriver(generation));
    return null;
  }

  void _assignDriver(int generation) {
    if (state.generation != generation) return;
    final ride = state.ride;
    if (ride == null || ride.stage != RideStage.searching) return;

    final bundle = _bundle;
    // Prefer drivers whose vehicle matches the selected category, then fall
    // back to the whole roster so a demo can never dead-end.
    final matching = [
      for (final driver in bundle.drivers)
        if (driver.vehicleId == ride.vehicle?.id) driver,
    ];
    final candidates = matching.isEmpty ? bundle.drivers : matching;

    final driver = DriverAssigner.assign(
      rideId: ride.id,
      candidates: candidates,
      seed: _seed,
    );
    if (driver == null) return;

    state = RideState(
      generation: generation,
      ride: ride.copyWith(stage: RideStage.driverAssigned, driverId: driver.id),
    );

    _schedule(SimulationTiming.driverApproach, () {
      _advance(
        generation,
        from: RideStage.driverAssigned,
        to: RideStage.driverArriving,
      );
    });
  }

  /// Confirms that the driver has reached the pickup point.
  AppFailure? startTrip() {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');
    if (ride.stage != RideStage.driverArriving) {
      return InvalidTransitionFailure(
        from: ride.stage.name,
        to: RideStage.inProgress.name,
      );
    }

    final generation = _bump();
    state = RideState(
      generation: generation,
      ride: ride.copyWith(stage: RideStage.inProgress, generation: generation),
    );
    _schedule(SimulationTiming.rideInProgress, () => _complete(generation));
    return null;
  }

  void _complete(int generation) {
    if (state.generation != generation) return;
    _advance(
      generation,
      from: RideStage.inProgress,
      to: RideStage.completed,
      progress: 1,
    );
  }

  void _advance(
    int generation, {
    required RideStage from,
    required RideStage to,
    double? progress,
  }) {
    if (state.generation != generation) return;
    final ride = state.ride;
    if (ride == null || ride.stage != from) return;
    if (!isValidRideTransition(from, to)) return;

    state = RideState(
      generation: generation,
      ride: ride.copyWith(stage: to, progress: progress),
    );
  }

  /// Settles the completed ride using [method].
  ///
  /// Commits payment and the activity record together, deducts the demo wallet
  /// once, and rejects a second payment.
  AppFailure? pay(String method) {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');
    if (ride.stage.isPayable == false) {
      // Covers both "too early" and "already paid".
      return ride.stage == RideStage.paid || ride.stage == RideStage.rated
          ? const DuplicateActionFailure.payment()
          : InvalidTransitionFailure(
              from: ride.stage.name,
              to: RideStage.paid.name,
            );
    }

    final total = ride.total;
    final isWallet = method == PaymentMethod.demoWallet;

    if (isWallet) {
      final profile = ref.read(profileProvider);
      if (profile.demoWalletBalance < total) {
        return InsufficientBalanceFailure(
          required: total,
          available: profile.demoWalletBalance,
        );
      }
    }

    final generation = _bump();
    state = RideState(
      generation: generation,
      ride: ride.copyWith(
        stage: RideStage.paid,
        paymentMethod: method,
        generation: generation,
      ),
    );

    if (isWallet) {
      ref.read(profileProvider.notifier).debitWallet(total);
    }

    ref
        .read(activityProvider.notifier)
        .record(
          ActivityRecord(
            journeyId: ride.id,
            kind: ActivityKind.ride,
            title: '${ride.pickup.name} → ${ride.destination.name}',
            subtitle: ride.vehicle?.label ?? 'Demo ride',
            amount: total,
            status: ActivityStatus.completed,
            createdAt: _clock.now(),
            paymentMethod: method,
          ),
        );

    return null;
  }

  /// Stores the star rating and closes the ride.
  AppFailure? submitRating(int stars) {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');
    if (!ride.stage.isRatable) {
      return const DuplicateActionFailure.activity();
    }

    final generation = _bump();
    state = RideState(
      generation: generation,
      ride: ride.copyWith(
        stage: RideStage.rated,
        rating: stars.clamp(1, 5),
        generation: generation,
      ),
    );

    ref.read(activityProvider.notifier).rateJourney(ride.id, stars.clamp(1, 5));
    return null;
  }

  /// Cancels the ride when the stage allows it, recording the outcome once.
  AppFailure? cancel() {
    final ride = state.ride;
    if (ride == null) return const NotFoundFailure(id: 'ride');
    if (!ride.isCancellable) {
      return InvalidTransitionFailure(
        from: ride.stage.name,
        to: RideStage.idle.name,
      );
    }

    // Only record an activity for rides the user actually booked.
    final wasBooked = ride.stage != RideStage.selecting;

    final generation = _bump();
    state = const RideState();

    if (wasBooked) {
      ref
          .read(activityProvider.notifier)
          .record(
            ActivityRecord(
              journeyId: ride.id,
              kind: ActivityKind.ride,
              title: '${ride.pickup.name} → ${ride.destination.name}',
              subtitle: 'Cancelled demo ride',
              amount: 0,
              status: ActivityStatus.cancelled,
              createdAt: _clock.now(),
            ),
          );
    }

    // Keep the generation monotonic so older callbacks stay invalid.
    state = RideState(generation: generation);
    return null;
  }

  /// Clears the ride without recording anything, used by reset.
  void reset() {
    _bump();
    state = RideState(generation: state.generation + 1);
  }

  void _schedule(Duration delay, void Function() callback) {
    _cancelPending();
    _pending = _clock.schedule(delay, () {
      _pending = null;
      callback();
    });
  }
}

/// Payment methods offered by the demo.
abstract final class PaymentMethod {
  static const String cash = 'cash';
  static const String demoWallet = 'wallet';
}

/// Provides the ride flow state.
final rideProvider = NotifierProvider<RideController, RideState>(
  RideController.new,
);
