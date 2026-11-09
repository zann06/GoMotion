import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/navigation/app_routes.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';
import 'package:gomotion/features/food/application/food_controller.dart';
import 'package:gomotion/features/home/application/active_journey_provider.dart';
import 'package:gomotion/features/ride/application/ride_controller.dart';
import 'package:gomotion/features/send/application/send_controller.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

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
  await container.read(fixtureBundleProvider.future);
  return (container, clock, bundle);
}

void main() {
  group('Active journey', () {
    test('is null while nothing is in progress', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      expect(container.read(activeJourneyProvider), isNull);
    });

    test(
      'surfaces a ride draft and follows it through its live screens',
      () async {
        final (container, clock, bundle) = await _harness();
        addTearDown(container.dispose);

        final ride = container.read(rideProvider.notifier);
        final pickup = bundle.defaultPickup;
        final destination = bundle.locations.firstWhere(
          (l) => l.id != pickup.id,
        );
        ride.beginDraft(pickup: pickup, destination: destination);

        final draft = container.read(activeJourneyProvider);
        expect(draft, isNotNull);
        expect(draft!.kind, ActiveJourneyKind.ride);
        expect(draft.location, AppRoutes.vehicleSelection);

        ride.selectVehicle(bundle.vehicles.first);
        ride.confirmBooking();
        expect(
          container.read(activeJourneyProvider)!.location,
          AppRoutes.rideMatching,
        );

        clock.advance(SimulationTiming.matching);
        clock.advance(SimulationTiming.driverApproach);
        ride.startTrip();
        expect(
          container.read(activeJourneyProvider)!.location,
          AppRoutes.rideTracking,
        );

        clock.advance(SimulationTiming.rideInProgress);
        final completed = container.read(activeJourneyProvider);
        expect(completed, isNotNull);
        expect(completed!.location, AppRoutes.ridePayment);
        expect(completed.actionLabel, 'Pay');

        // A settled ride is no longer something to resume.
        ride.pay(PaymentMethod.cash);
        expect(container.read(activeJourneyProvider), isNull);
      },
    );

    test('an untouched send draft is ignored, a live order is not', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      // Opening GoSend always creates a draft; an empty one is not resumable.
      container.read(sendProvider.notifier).startDraft();
      expect(container.read(activeJourneyProvider), isNull);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();
      food.placeOrder(paymentMethod: FoodPayment.cash);

      final journey = container.read(activeJourneyProvider);
      expect(journey, isNotNull);
      expect(journey!.kind, ActiveJourneyKind.food);
      expect(journey.location, AppRoutes.foodTracking);
    });

    test('a send draft with input becomes resumable', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final send = container.read(sendProvider.notifier);
      send.startDraft();
      send.updateDraft(senderName: 'Demo Sender');

      final journey = container.read(activeJourneyProvider);
      expect(journey, isNotNull);
      expect(journey!.kind, ActiveJourneyKind.send);
      expect(journey.location, AppRoutes.send);
    });
  });
}
