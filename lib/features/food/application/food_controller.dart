import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/activity_record.dart';
import '../../../domain/entities/fixtures.dart';
import '../../../domain/entities/food_order.dart';
import '../../../domain/repositories/fixture_repository.dart';
import '../../../simulation/driver_assigner.dart';
import '../../../simulation/simulation_clock.dart';
import '../../activity/application/activity_controller.dart';
import '../../profile/application/profile_controller.dart';

/// Snapshot of the GoFood flow.
class FoodState {
  const FoodState({this.order, this.generation = 0});

  final FoodOrder? order;
  final int generation;

  bool get hasOrder => order != null;

  /// The current stage, defaulting to [FoodStage.browsing].
  FoodStage get stage => order?.stage ?? FoodStage.browsing;

  @override
  bool operator ==(Object other) =>
      other is FoodState &&
      other.order == order &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(order, generation);
}

/// Drives the simulated GoFood order lifecycle.
///
/// Cart rules: quantity can never go below zero, an empty cart cannot be
/// checked out, and only one restaurant may be ordered from at a time.
class FoodController extends Notifier<FoodState> {
  CancelTask? _pending;

  @override
  FoodState build() {
    ref.onDispose(_cancelPending);
    return const FoodState();
  }

  FixtureBundle get _bundle {
    final bundle = ref.read(fixtureBundleProvider).value;
    if (bundle == null) {
      throw StateError('Food flow requires loaded fixtures.');
    }
    return bundle;
  }

  SimulationClock get _clock => ref.read(simulationClockProvider);

  void _cancelPending() {
    _pending?.call();
    _pending = null;
  }

  int _bump() {
    _cancelPending();
    return state.generation + 1;
  }

  /// Opens [restaurant], discarding any cart from a different restaurant.
  void selectRestaurant(Restaurant restaurant) {
    final existing = state.order;
    final sameRestaurant = existing?.restaurantId == restaurant.id;

    if (existing != null && sameRestaurant) {
      // Keep the cart when re-opening the same restaurant.
      state = FoodState(
        generation: state.generation,
        order: existing.copyWith(
          stage: existing.lines.isEmpty
              ? FoodStage.restaurantSelected
              : FoodStage.cartReady,
        ),
      );
      return;
    }

    final generation = _bump();
    state = FoodState(
      generation: generation,
      order: FoodOrder(
        id: existing?.id ?? 'food_${DateTime.now().microsecondsSinceEpoch}',
        stage: FoodStage.restaurantSelected,
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        deliveryFee: _defaultDeliveryFee,
        generation: generation,
      ),
    );
  }

  /// The GoFood delivery fee from the fixture dataset.
  int get _defaultDeliveryFee {
    final options = _bundle.deliveryOptions;
    for (final option in options) {
      if (option.serviceType == 'GoFood') return option.baseFee;
    }
    return options.isEmpty ? 0 : options.first.baseFee;
  }

  /// Adds one of [item] to the cart, creating the order when none exists.
  ///
  /// Returns a typed failure when the item belongs to a different restaurant or
  /// is unavailable.
  AppFailure? addItem(MenuItem item) {
    if (!item.available) {
      return const ValidationFailure(
        field: 'menu_item',
        message: 'This demo item is currently unavailable.',
      );
    }

    var order = state.order;
    if (order == null) {
      final restaurant = _bundle.restaurant(item.restaurantId);
      order = FoodOrder(
        id: 'food_${DateTime.now().microsecondsSinceEpoch}',
        stage: FoodStage.cartReady,
        restaurantId: item.restaurantId,
        restaurantName: restaurant?.name ?? 'Demo restaurant',
        deliveryFee: _defaultDeliveryFee,
        generation: state.generation,
      );
    } else if (order.restaurantId != item.restaurantId) {
      return const ValidationFailure(
        field: 'cart_restaurant',
        message:
            'Your demo cart already contains items from another restaurant.',
      );
    }

    final lines = [...order.lines];
    final index = lines.indexWhere((l) => l.itemId == item.id);
    if (index >= 0) {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    } else {
      lines.add(
        CartLine(
          itemId: item.id,
          name: item.name,
          unitPrice: item.price,
          quantity: 1,
          imageAsset: item.imageAsset,
        ),
      );
    }

    state = FoodState(
      generation: state.generation,
      order: order.copyWith(stage: FoodStage.cartReady, lines: lines),
    );
    return null;
  }

  /// Increments an existing line, used by the cart's stepper.
  ///
  /// A no-op when the line is absent, so the stepper can never create a line
  /// for an item that is not already in the cart.
  void incrementItem(String itemId) {
    final order = state.order;
    if (order == null) return;

    final index = order.lines.indexWhere((l) => l.itemId == itemId);
    if (index < 0) return;

    final lines = [...order.lines];
    lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);

    state = FoodState(
      generation: state.generation,
      order: order.copyWith(stage: FoodStage.cartReady, lines: lines),
    );
  }

  /// Removes one of [itemId], dropping the line at zero quantity.
  void removeItem(String itemId) {
    final order = state.order;
    if (order == null) return;

    final lines = <CartLine>[];
    for (final line in order.lines) {
      if (line.itemId != itemId) {
        lines.add(line);
      } else if (line.quantity > 1) {
        lines.add(line.copyWith(quantity: line.quantity - 1));
      }
      // At quantity 1 the line is dropped entirely; quantity never goes below 0.
    }

    state = FoodState(
      generation: state.generation,
      order: order.copyWith(
        lines: lines,
        stage: lines.isEmpty
            ? FoodStage.restaurantSelected
            : FoodStage.cartReady,
      ),
    );
  }

  /// Empties the cart but keeps the restaurant selected.
  void clearCart() {
    final order = state.order;
    if (order == null) return;
    state = FoodState(
      generation: state.generation,
      order: order.copyWith(
        lines: const [],
        stage: FoodStage.restaurantSelected,
      ),
    );
  }

  /// Advances to checkout, refusing an empty cart.
  AppFailure? beginCheckout() {
    final order = state.order;
    if (order == null) return const NotFoundFailure(id: 'food_cart');
    if (order.isEmpty) {
      return const ValidationFailure(
        field: 'cart',
        message: 'Add at least one demo item before checking out.',
      );
    }

    state = FoodState(
      generation: state.generation,
      order: order.copyWith(stage: FoodStage.checkout),
    );
    return null;
  }

  /// Places the order and starts courier matching.
  AppFailure? placeOrder({required String paymentMethod}) {
    final order = state.order;
    if (order == null) return const NotFoundFailure(id: 'food_cart');
    if (order.isEmpty) {
      return const ValidationFailure(
        field: 'cart',
        message: 'Add at least one demo item before checking out.',
      );
    }
    if (order.stage != FoodStage.checkout) {
      return InvalidTransitionFailure(
        from: order.stage.name,
        to: FoodStage.matchingCourier.name,
      );
    }

    final total = order.total;
    if (paymentMethod == FoodPayment.demoWallet) {
      final balance = ref.read(profileProvider).demoWalletBalance;
      if (balance < total) {
        return InsufficientBalanceFailure(required: total, available: balance);
      }
      ref.read(profileProvider.notifier).debitWallet(total);
    }

    final generation = _bump();
    state = FoodState(
      generation: generation,
      order: order.copyWith(
        stage: FoodStage.matchingCourier,
        paymentMethod: paymentMethod,
        generation: generation,
      ),
    );

    _schedule(SimulationTiming.courierMatching, () {
      _advance(
        generation,
        from: FoodStage.matchingCourier,
        to: FoodStage.preparing,
      );
    });
    return null;
  }

  void _advance(
    int generation, {
    required FoodStage from,
    required FoodStage to,
  }) {
    if (state.generation != generation) return;
    final order = state.order;
    if (order == null || order.stage != from) return;
    if (!isValidFoodTransition(from, to)) return;

    if (to == FoodStage.preparing) {
      final courier = DriverAssigner.assign(
        rideId: order.id,
        candidates: _bundle.drivers,
        seed: AppInfo.simulationSeed,
      );
      state = FoodState(
        generation: generation,
        order: order.copyWith(
          stage: to,
          courierId: courier?.id,
          progress: 0.33,
        ),
      );
      _schedule(SimulationTiming.preparing, () {
        _advance(generation, from: to, to: FoodStage.onTheWay);
      });
      return;
    }

    state = FoodState(
      generation: generation,
      order: order.copyWith(
        stage: to,
        progress: to == FoodStage.onTheWay ? 0.66 : 1,
      ),
    );

    if (to == FoodStage.onTheWay) {
      _schedule(SimulationTiming.inTransit, () {
        _advance(generation, from: to, to: FoodStage.delivered);
      });
    } else if (to == FoodStage.delivered) {
      _finish(generation);
    }
  }

  /// Records the delivered order exactly once.
  void _finish(int generation) {
    if (state.generation != generation) return;
    final order = state.order;
    if (order == null || order.stage != FoodStage.delivered) return;

    ref
        .read(activityProvider.notifier)
        .record(
          ActivityRecord(
            journeyId: order.id,
            kind: ActivityKind.food,
            title: order.restaurantName ?? 'Demo food order',
            subtitle:
                '${order.itemCount} demo '
                '${order.itemCount == 1 ? 'item' : 'items'} delivered',
            amount: order.total,
            status: ActivityStatus.completed,
            createdAt: _clock.now(),
            paymentMethod: order.paymentMethod,
          ),
        );
  }

  /// Cancels before preparation, recording a zero-amount cancelled entry.
  AppFailure? cancel() {
    final order = state.order;
    if (order == null) return const NotFoundFailure(id: 'food_cart');
    if (!order.stage.isCancellable) {
      return InvalidTransitionFailure(
        from: order.stage.name,
        to: FoodStage.browsing.name,
      );
    }

    final wasPlaced =
        order.stage == FoodStage.checkout ||
        order.stage == FoodStage.matchingCourier;

    final generation = _bump();

    if (wasPlaced) {
      // Refund the demo wallet if it was charged at placement.
      if (order.paymentMethod == FoodPayment.demoWallet) {
        ref.read(profileProvider.notifier).creditWallet(order.total);
      }
      ref
          .read(activityProvider.notifier)
          .record(
            ActivityRecord(
              journeyId: order.id,
              kind: ActivityKind.food,
              title: order.restaurantName ?? 'Demo food order',
              subtitle: 'Cancelled demo order',
              amount: 0,
              status: ActivityStatus.cancelled,
              createdAt: _clock.now(),
            ),
          );
    }

    state = FoodState(generation: generation);
    return null;
  }

  /// Clears the flow without recording anything, used by reset.
  void reset() {
    _bump();
    state = FoodState(generation: state.generation + 1);
  }

  void _schedule(Duration delay, void Function() callback) {
    _cancelPending();
    _pending = _clock.schedule(delay, () {
      _pending = null;
      callback();
    });
  }
}

/// Payment methods offered by the demo food flow.
abstract final class FoodPayment {
  static const String cash = 'cash';
  static const String demoWallet = 'wallet';
}

/// Provides the GoFood flow state.
final foodProvider = NotifierProvider<FoodController, FoodState>(
  FoodController.new,
);
