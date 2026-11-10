import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/errors/app_failure.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/data/repositories/json_fixture_repository.dart';
import 'package:gomotion/domain/entities/activity_record.dart';
import 'package:gomotion/domain/entities/fixtures.dart';
import 'package:gomotion/domain/entities/food_order.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';
import 'package:gomotion/features/activity/application/activity_controller.dart';
import 'package:gomotion/features/food/application/food_controller.dart';
import 'package:gomotion/features/profile/application/profile_controller.dart';
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
  group('GoFood flow', () {
    test('runs the full lifecycle to a delivered order', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      final items = bundle.menuFor(restaurant.id);

      food.selectRestaurant(restaurant);
      expect(container.read(foodProvider).stage, FoodStage.restaurantSelected);

      expect(food.addItem(items.first), isNull);
      expect(container.read(foodProvider).stage, FoodStage.cartReady);
      expect(container.read(foodProvider).order!.itemCount, 1);

      expect(food.beginCheckout(), isNull);
      expect(container.read(foodProvider).stage, FoodStage.checkout);

      expect(food.placeOrder(paymentMethod: FoodPayment.cash), isNull);
      expect(container.read(foodProvider).stage, FoodStage.matchingCourier);

      clock.advance(SimulationTiming.courierMatching);
      expect(container.read(foodProvider).stage, FoodStage.preparing);
      expect(container.read(foodProvider).order!.courierId, isNotNull);

      clock.advance(SimulationTiming.preparing);
      expect(container.read(foodProvider).stage, FoodStage.onTheWay);

      clock.advance(SimulationTiming.inTransit);
      expect(container.read(foodProvider).stage, FoodStage.delivered);

      final activity = container.read(activityProvider);
      expect(activity, hasLength(1));
      expect(activity.single.kind, ActivityKind.food);
      expect(activity.single.status, ActivityStatus.completed);
    });

    test('quantity never falls below zero', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      final item = bundle.menuFor(restaurant.id).first;

      food.selectRestaurant(restaurant);
      food.addItem(item);
      food.addItem(item);
      expect(container.read(foodProvider).order!.quantityOf(item.id), 2);

      food.removeItem(item.id);
      expect(container.read(foodProvider).order!.quantityOf(item.id), 1);

      food.removeItem(item.id);
      expect(container.read(foodProvider).order!.quantityOf(item.id), 0);

      // Further removals must stay at zero rather than going negative.
      food.removeItem(item.id);
      expect(container.read(foodProvider).order!.quantityOf(item.id), 0);
      expect(container.read(foodProvider).order!.isEmpty, isTrue);
    });

    test('an empty cart cannot be checked out', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      food.selectRestaurant(bundle.restaurants.first);

      final failure = food.beginCheckout();
      expect(failure, isNotNull);
      expect(failure!.code, 'validation_cart');
      expect(container.read(foodProvider).stage, FoodStage.restaurantSelected);
    });

    test('rejects items from a different restaurant', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final first = bundle.restaurants[0];
      final second = bundle.restaurants[1];

      food.selectRestaurant(first);
      food.addItem(bundle.menuFor(first.id).first);

      final failure = food.addItem(bundle.menuFor(second.id).first);
      expect(failure, isNotNull);
      expect(failure!.code, 'validation_cart_restaurant');
    });

    test('cancelling before preparation refunds the demo wallet', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();

      final before = container.read(profileProvider).demoWalletBalance;
      final total = container.read(foodProvider).order!.total;

      expect(food.placeOrder(paymentMethod: FoodPayment.demoWallet), isNull);
      expect(container.read(profileProvider).demoWalletBalance, before - total);

      clock.advance(SimulationTiming.courierMatching);
      expect(container.read(foodProvider).stage, FoodStage.preparing);

      // Preparation has begun: cancellation must now be refused.
      final refused = food.cancel();
      expect(refused, isNotNull);
      expect(container.read(foodProvider).stage, FoodStage.preparing);
    });

    test('cancelling while matching refunds and records once', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();

      final before = container.read(profileProvider).demoWalletBalance;
      final total = container.read(foodProvider).order!.total;
      food.placeOrder(paymentMethod: FoodPayment.demoWallet);

      expect(food.cancel(), isNull);
      expect(
        container.read(profileProvider).demoWalletBalance,
        before,
        reason: 'The demo wallet must be restored on cancellation.',
      );
      expect(container.read(foodProvider).order, isNull);

      final activity = container.read(activityProvider);
      expect(activity, hasLength(1));
      expect(activity.single.status, ActivityStatus.cancelled);
      expect(total, greaterThan(0));
    });

    test('stale timers cannot revive a cancelled order', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();
      food.placeOrder(paymentMethod: FoodPayment.cash);

      food.cancel();
      clock.advance(const Duration(minutes: 5));

      expect(container.read(foodProvider).order, isNull);
      expect(container.read(activityProvider), hasLength(1));
    });

    test('reset clears order state and pending timers', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();
      food.placeOrder(paymentMethod: FoodPayment.cash);

      food.reset();
      expect(container.read(foodProvider).order, isNull);
      expect(clock.pendingCount, 0);

      clock.advance(const Duration(minutes: 5));
      expect(container.read(activityProvider), isEmpty);
    });

    test('cart edits are locked once checkout begins', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      final item = bundle.menuFor(restaurant.id).first;

      food.selectRestaurant(restaurant);
      expect(food.addItem(item), isNull);
      expect(food.beginCheckout(), isNull);

      // No further edits, and the checkout cannot be entered twice.
      expect(food.addItem(item), isNotNull);
      expect(container.read(foodProvider).order!.itemCount, 1);
      expect(food.beginCheckout(), isA<InvalidTransitionFailure>());
      expect(container.read(foodProvider).stage, FoodStage.checkout);

      // Quantity steppers must also be inert outside the editable stages.
      food.incrementItem(item.id);
      food.removeItem(item.id);
      expect(container.read(foodProvider).order!.itemCount, 1);
    });

    test('a delivered order cannot be edited or re-checked-out', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      final item = bundle.menuFor(restaurant.id).first;

      food.selectRestaurant(restaurant);
      food.addItem(item);
      food.beginCheckout();
      food.placeOrder(paymentMethod: FoodPayment.cash);
      clock.advance(SimulationTiming.courierMatching);
      clock.advance(SimulationTiming.preparing);
      clock.advance(SimulationTiming.inTransit);
      expect(container.read(foodProvider).stage, FoodStage.delivered);

      expect(food.addItem(item), isNotNull);
      expect(food.beginCheckout(), isA<InvalidTransitionFailure>());
      expect(container.read(foodProvider).stage, FoodStage.delivered);
    });

    test('delivering an order rewards demo points exactly once', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      final food = container.read(foodProvider.notifier);
      final restaurant = bundle.restaurants.first;
      food.selectRestaurant(restaurant);
      food.addItem(bundle.menuFor(restaurant.id).first);
      food.beginCheckout();

      final pointsBefore = container.read(profileProvider).rewardPoints;
      food.placeOrder(paymentMethod: FoodPayment.cash);
      clock.advance(SimulationTiming.courierMatching);
      clock.advance(SimulationTiming.preparing);
      clock.advance(SimulationTiming.inTransit);

      expect(container.read(foodProvider).stage, FoodStage.delivered);
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore + AppInfo.demoPointsPerJourney,
      );

      // Later ticks must not award the same journey twice.
      clock.advance(const Duration(minutes: 5));
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore + AppInfo.demoPointsPerJourney,
      );
    });
  });

  group('GoFood browse filtering', () {
    // Synthetic kitchens so every filter branch is exercised regardless of how
    // the bundled fixture evolves.
    const asian = Restaurant(
      id: 'rest_a',
      name: 'Nori House',
      category: 'Asian',
      rating: 4.8,
      distanceKm: 1.2,
      etaLabel: '20–30 min',
      imageAsset: 'nori_house.png',
      featured: true,
    );
    const dessert = Restaurant(
      id: 'rest_b',
      name: 'Sweet Corner',
      category: 'Dessert',
      rating: 4.7,
      distanceKm: 3.4,
      etaLabel: '15–25 min',
      imageAsset: 'sweet_corner.png',
      featured: false,
    );

    test('categories cover every bundled restaurant category', () async {
      final bundle = await JsonFixtureRepository().load();
      for (final restaurant in bundle.restaurants) {
        expect(
          foodCategories,
          contains(restaurant.category),
          reason: '${restaurant.name} must match a browse category tile',
        );
      }
    });

    test('no filter returns every kitchen', () {
      final result = filterRestaurants([asian, dessert]);
      expect(result, [asian, dessert]);
    });

    test('category keeps only matching kitchens', () {
      expect(filterRestaurants([asian, dessert], category: 'Asian'), [asian]);
      expect(filterRestaurants([asian, dessert], category: 'Dessert'), [
        dessert,
      ]);
      expect(filterRestaurants([asian], category: 'Western'), isEmpty);
    });

    test('query matches name or category, case-insensitively', () {
      expect(filterRestaurants([asian, dessert], query: 'nori'), [asian]);
      expect(filterRestaurants([asian, dessert], query: 'SWEET'), [dessert]);
      expect(filterRestaurants([asian, dessert], query: 'dessert'), [dessert]);
      expect(filterRestaurants([asian, dessert], query: 'zzz'), isEmpty);
    });

    test('category and query combine with AND', () {
      expect(
        filterRestaurants([asian, dessert], category: 'Asian', query: 'nori'),
        [asian],
      );
      expect(
        filterRestaurants([asian, dessert], category: 'Asian', query: 'sweet'),
        isEmpty,
      );
    });

    test('blank query behaves like no query after trimming', () {
      expect(filterRestaurants([asian, dessert], query: '  '), [
        asian,
        dessert,
      ]);
    });
  });
}
