import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/errors/app_failure.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/entities/activity_record.dart';
import 'package:gomotion/domain/entities/fixtures.dart';
import 'package:gomotion/domain/entities/ride.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';
import 'package:gomotion/features/activity/application/activity_controller.dart';
import 'package:gomotion/features/profile/application/profile_controller.dart';
import 'package:gomotion/features/ride/application/ride_controller.dart';
import 'package:gomotion/simulation/driver_assigner.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

/// Builds a container wired to a deterministic clock and the real fixtures.
Future<(ProviderContainer, FakeSimulationClock, FixtureBundle)>
_harness() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bundle = await JsonFixtureRepository().load();
  final clock = FakeSimulationClock();

  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      simulationClockProvider.overrideWithValue(clock),
    ],
  );

  // Resolve the fixture future so synchronous reads inside controllers work.
  await container.read(fixtureBundleProvider.future);
  return (container, clock, bundle);
}

/// Picks two distinct demo locations for a trip.
(Location, Location) _endpoints(FixtureBundle bundle) {
  final pickup = bundle.defaultPickup;
  final destination = bundle.locations.firstWhere((l) => l.id != pickup.id);
  return (pickup, destination);
}

void main() {
  group('Ride flow', () {
    test('advances through the full lifecycle on clock ticks', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);

      ride.beginDraft(pickup: pickup, destination: destination);
      expect(container.read(rideProvider).stage, RideStage.selecting);

      final vehicle = bundle.vehicles.first;
      ride.selectVehicle(vehicle);
      expect(container.read(rideProvider).ride!.total, greaterThan(0));

      expect(ride.confirmBooking(), isNull);
      expect(container.read(rideProvider).stage, RideStage.searching);

      clock.advance(SimulationTiming.matching);
      final assigned = container.read(rideProvider).ride!;
      expect(assigned.stage, RideStage.driverAssigned);
      expect(assigned.driverId, isNotNull);

      clock.advance(SimulationTiming.driverApproach);
      expect(container.read(rideProvider).stage, RideStage.driverArriving);

      expect(ride.startTrip(), isNull);
      expect(container.read(rideProvider).stage, RideStage.inProgress);

      clock.advance(SimulationTiming.rideInProgress);
      expect(container.read(rideProvider).stage, RideStage.completed);

      expect(ride.pay(PaymentMethod.cash), isNull);
      expect(container.read(rideProvider).stage, RideStage.paid);

      expect(ride.submitRating(5), isNull);
      final finalRide = container.read(rideProvider).ride!;
      expect(finalRide.stage, RideStage.rated);
      expect(finalRide.rating, 5);
    });

    test('driver assignment is deterministic for the same ride id', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      // Exercise the real assigner with the same candidate rule the controller
      // uses, so this test fails if assignment ever stops being reproducible.
      final vehicleId = bundle.vehicles.first.id;
      final matching = [
        for (final driver in bundle.drivers)
          if (driver.vehicleId == vehicleId) driver,
      ];
      final candidates = matching.isEmpty ? bundle.drivers : matching;

      final first = DriverAssigner.assign(
        rideId: 'fixed_ride_id',
        candidates: candidates,
        seed: AppInfo.simulationSeed,
      );
      final second = DriverAssigner.assign(
        rideId: 'fixed_ride_id',
        candidates: candidates,
        seed: AppInfo.simulationSeed,
      );

      expect(first, isNotNull);
      expect(first!.id, second!.id);
    });

    test('rejects a second booking confirmation', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);

      expect(ride.confirmBooking(), isNull);
      final duplicate = ride.confirmBooking();

      expect(duplicate, isA<DuplicateActionFailure>());
      expect(duplicate!.code, 'duplicate_booking');
    });

    test('cancellation stops pending timers and records once', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);
      ride.confirmBooking();

      expect(clock.pendingCount, greaterThan(0));

      expect(ride.cancel(), isNull);
      expect(container.read(rideProvider).ride, isNull);
      expect(clock.pendingCount, 0);

      final activity = container.read(activityProvider);
      expect(activity, hasLength(1));
      expect(activity.single.status, ActivityStatus.cancelled);

      // Advancing past the original matching window must change nothing.
      clock.advance(const Duration(minutes: 1));
      expect(container.read(rideProvider).ride, isNull);
      expect(container.read(activityProvider), hasLength(1));
    });

    test('a stale timer after cancellation cannot revive the ride', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);
      ride.confirmBooking();

      // Cancel, then start a fresh draft and cancel timing assumptions.
      ride.cancel();
      clock.advance(SimulationTiming.matching);

      expect(container.read(rideProvider).ride, isNull);
    });

    test('second payment is rejected and wallet is debited once', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.firstWhere((v) => v.id == 'veh_ride'));
      ride.confirmBooking();
      clock.advance(SimulationTiming.matching);
      clock.advance(SimulationTiming.driverApproach);
      ride.startTrip();
      clock.advance(SimulationTiming.rideInProgress);

      final total = container.read(rideProvider).ride!.total;
      final before = container.read(profileProvider).demoWalletBalance;

      expect(ride.pay(PaymentMethod.demoWallet), isNull);
      expect(container.read(profileProvider).demoWalletBalance, before - total);

      final duplicate = ride.pay(PaymentMethod.demoWallet);
      expect(duplicate, isA<DuplicateActionFailure>());
      expect(duplicate!.code, 'duplicate_payment');
      // A rejected retry must not debit again.
      expect(container.read(profileProvider).demoWalletBalance, before - total);
      expect(container.read(activityProvider), hasLength(1));
    });

    test('wallet payment fails when the balance is too low', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(
        bundle.vehicles.firstWhere((v) => v.id == 'veh_premium'),
      );
      ride.confirmBooking();
      clock.advance(SimulationTiming.matching);
      clock.advance(SimulationTiming.driverApproach);
      ride.startTrip();
      clock.advance(SimulationTiming.rideInProgress);

      // Drain the wallet below the fare.
      container
          .read(profileProvider.notifier)
          .debitWallet(container.read(profileProvider).demoWalletBalance - 1);

      final failure = ride.pay(PaymentMethod.demoWallet);
      expect(failure, isA<InsufficientBalanceFailure>());
      expect(container.read(rideProvider).stage, RideStage.completed);
      expect(container.read(activityProvider), isEmpty);
    });

    test('cancelling during an active trip is refused', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);
      ride.confirmBooking();
      clock.advance(SimulationTiming.matching);
      clock.advance(SimulationTiming.driverApproach);
      ride.startTrip();

      final failure = ride.cancel();
      expect(failure, isA<InvalidTransitionFailure>());
      expect(container.read(rideProvider).stage, RideStage.inProgress);
    });

    test('promo application rejects unknown and ineligible codes', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);

      expect(ride.applyPromoCode('NOPE')!.code, 'promo_not_found');
      expect(ride.applyPromoCode('move10'), isNull);
      expect(container.read(rideProvider).ride!.promoCode, 'MOVE10');

      ride.clearPromo();
      expect(container.read(rideProvider).ride!.promoCode, isNull);
    });

    test('keeps an eligible promo when the selected vehicle changes', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);

      final cheapest = bundle.vehicles.firstWhere((v) => v.id == 'veh_ride');
      final premium = bundle.vehicles.firstWhere((v) => v.id == 'veh_premium');
      ride.selectVehicle(cheapest);
      expect(ride.applyPromoCode('MOVE10'), isNull);
      expect(container.read(rideProvider).ride!.promoCode, 'MOVE10');

      // Re-selecting a vehicle must not silently drop the applied discount.
      ride.selectVehicle(premium);
      expect(container.read(rideProvider).ride!.promoCode, 'MOVE10');
      expect(container.read(rideProvider).ride!.fare!.discount, greaterThan(0));

      // An explicit removal still clears it.
      ride.clearPromo();
      expect(container.read(rideProvider).ride!.promoCode, isNull);
    });

    test('rewards demo points once when a ride is paid', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);
      ride.confirmBooking();
      clock.advance(SimulationTiming.matching);
      clock.advance(SimulationTiming.driverApproach);
      ride.startTrip();
      clock.advance(SimulationTiming.rideInProgress);

      final pointsBefore = container.read(profileProvider).rewardPoints;
      expect(ride.pay(PaymentMethod.cash), isNull);
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore + AppInfo.demoPointsPerJourney,
      );

      // A rejected retry must not grant points twice.
      ride.pay(PaymentMethod.cash);
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore + AppInfo.demoPointsPerJourney,
      );
    });

    test('reset clears ride state and leaves no pending timers', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final ride = container.read(rideProvider.notifier);
      final (pickup, destination) = _endpoints(bundle);
      ride.beginDraft(pickup: pickup, destination: destination);
      ride.selectVehicle(bundle.vehicles.first);
      ride.confirmBooking();

      ride.reset();
      expect(container.read(rideProvider).ride, isNull);
      expect(clock.pendingCount, 0);

      clock.advance(const Duration(minutes: 5));
      expect(container.read(rideProvider).ride, isNull);
      expect(container.read(activityProvider), isEmpty);
    });
  });

  group('Activity ledger', () {
    test('rejects a duplicate record for the same journey', () async {
      final (container, clock, _) = await _harness();
      addTearDown(container.dispose);

      final record = ActivityRecord(
        journeyId: 'j1',
        kind: ActivityKind.ride,
        title: 'A → B',
        subtitle: 'GoCar',
        amount: 1000,
        status: ActivityStatus.completed,
        createdAt: clock.now(),
      );

      final ledger = container.read(activityProvider.notifier);
      expect(ledger.record(record), isTrue);
      expect(ledger.record(record), isFalse);
      expect(container.read(activityProvider), hasLength(1));
    });

    test('rates an existing record in place', () async {
      final (container, clock, _) = await _harness();
      addTearDown(container.dispose);

      final record = ActivityRecord(
        journeyId: 'j2',
        kind: ActivityKind.ride,
        title: 'A → B',
        subtitle: 'GoCar',
        amount: 1000,
        status: ActivityStatus.completed,
        createdAt: clock.now(),
      );

      final ledger = container.read(activityProvider.notifier);
      ledger.record(record);
      ledger.rateJourney('j2', 4);

      expect(container.read(activityProvider).single.rating, 4);
      expect(container.read(activityProvider), hasLength(1));
    });
  });
}
