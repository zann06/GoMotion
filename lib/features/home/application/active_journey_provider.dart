import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../domain/entities/food_order.dart';
import '../../../domain/entities/parcel_delivery.dart';
import '../../../domain/entities/ride.dart';
import '../../food/application/food_controller.dart';
import '../../ride/application/ride_controller.dart';
import '../../send/application/send_controller.dart';

/// The three demo services that can own a journey in progress.
enum ActiveJourneyKind {
  ride('Ride'),
  food('Food'),
  send('Send');

  const ActiveJourneyKind(this.label);

  /// Human-readable service name.
  final String label;
}

/// A journey the user can jump straight back into from the home dashboard.
///
/// Without this, leaving an active ride, order, or parcel strand the only route
/// back into its live screens behind a fresh draft, which silently discards the
/// journey in progress.
@immutable
class ActiveJourney {
  const ActiveJourney({
    required this.kind,
    required this.title,
    required this.detail,
    required this.location,
    required this.actionLabel,
  });

  final ActiveJourneyKind kind;

  /// Headline, e.g. `Ride to Campus Hub`.
  final String title;

  /// One-line status, e.g. `On the way`.
  final String detail;

  /// Router location to reopen the journey.
  final String location;

  /// Label for the resume action.
  final String actionLabel;
}

/// The single most important journey still in progress, or null when the user
/// is not partway through anything.
///
/// Ride wins over GoFood, which wins over GoSend; in practice only one flow can
/// be active at a time, and a deterministic order keeps the dashboard stable.
final activeJourneyProvider = Provider<ActiveJourney?>((ref) {
  final ride = ref.watch(rideProvider).ride;
  final order = ref.watch(foodProvider).order;
  final parcel = ref.watch(sendProvider).parcel;

  return _fromRide(ride) ?? _fromFood(order) ?? _fromSend(parcel);
});

ActiveJourney? _fromRide(Ride? ride) {
  if (ride == null) return null;
  final destination = ride.destination.name;
  switch (ride.stage) {
    case RideStage.selecting:
      return ActiveJourney(
        kind: ActiveJourneyKind.ride,
        title: 'Ride to $destination',
        detail: 'Demo draft · choose a vehicle',
        location: AppRoutes.vehicleSelection,
        actionLabel: 'Resume',
      );
    case RideStage.searching:
    case RideStage.driverAssigned:
    case RideStage.driverArriving:
      return ActiveJourney(
        kind: ActiveJourneyKind.ride,
        title: 'Ride to $destination',
        detail: 'Finding a demo driver',
        location: AppRoutes.rideMatching,
        actionLabel: 'Resume',
      );
    case RideStage.inProgress:
      return ActiveJourney(
        kind: ActiveJourneyKind.ride,
        title: 'Ride to $destination',
        detail: 'On the way',
        location: AppRoutes.rideTracking,
        actionLabel: 'Resume',
      );
    case RideStage.completed:
      return ActiveJourney(
        kind: ActiveJourneyKind.ride,
        title: 'Ride to $destination',
        detail: 'Completed · payment pending',
        location: AppRoutes.ridePayment,
        actionLabel: 'Pay',
      );
    case RideStage.idle:
    case RideStage.paid:
    case RideStage.rated:
      return null;
  }
}

ActiveJourney? _fromFood(FoodOrder? order) {
  if (order == null) return null;
  final name = order.restaurantName ?? 'demo restaurant';
  switch (order.stage) {
    case FoodStage.browsing:
    case FoodStage.receipt:
      return null;
    case FoodStage.restaurantSelected:
      return ActiveJourney(
        kind: ActiveJourneyKind.food,
        title: 'Food from $name',
        detail: 'Demo cart open',
        location: order.restaurantId == null
            ? AppRoutes.foodCart
            : AppRoutes.foodRestaurantPath(order.restaurantId!),
        actionLabel: 'Resume',
      );
    case FoodStage.cartReady:
      return ActiveJourney(
        kind: ActiveJourneyKind.food,
        title: 'Food from $name',
        detail:
            '${order.itemCount} demo '
            '${order.itemCount == 1 ? 'item' : 'items'} in the cart',
        location: AppRoutes.foodCart,
        actionLabel: 'Resume',
      );
    case FoodStage.checkout:
      return ActiveJourney(
        kind: ActiveJourneyKind.food,
        title: 'Food from $name',
        detail: 'Demo checkout not completed',
        location: AppRoutes.foodCheckout,
        actionLabel: 'Resume',
      );
    case FoodStage.matchingCourier:
    case FoodStage.preparing:
    case FoodStage.onTheWay:
    case FoodStage.delivered:
      return ActiveJourney(
        kind: ActiveJourneyKind.food,
        title: 'Food from $name',
        detail: order.stage == FoodStage.delivered
            ? 'Delivered'
            : 'Demo order on the way',
        location: AppRoutes.foodTracking,
        actionLabel: 'Track',
      );
  }
}

ActiveJourney? _fromSend(ParcelDelivery? parcel) {
  if (parcel == null) return null;
  final recipient = parcel.recipientName.trim().isEmpty
      ? 'recipient'
      : parcel.recipientName;
  switch (parcel.stage) {
    case SendStage.draft:
      // Opening GoSend creates an empty draft automatically, so only surface it
      // once the user has actually typed something worth returning to.
      final hasInput =
          parcel.senderName.trim().isNotEmpty ||
          parcel.senderAddress.trim().isNotEmpty ||
          parcel.recipientName.trim().isNotEmpty ||
          parcel.recipientAddress.trim().isNotEmpty ||
          parcel.category != null;
      if (!hasInput) return null;
      return ActiveJourney(
        kind: ActiveJourneyKind.send,
        title: 'Parcel to $recipient',
        detail: 'Demo draft not finished',
        location: AppRoutes.send,
        actionLabel: 'Resume',
      );
    case SendStage.quoted:
      return ActiveJourney(
        kind: ActiveJourneyKind.send,
        title: 'Parcel to $recipient',
        detail: 'Demo quote ready to confirm',
        location: AppRoutes.sendReview,
        actionLabel: 'Resume',
      );
    case SendStage.confirmed:
    case SendStage.matchingCourier:
    case SendStage.courierAssigned:
    case SendStage.pickedUp:
    case SendStage.inTransit:
    case SendStage.delivered:
      return ActiveJourney(
        kind: ActiveJourneyKind.send,
        title: 'Parcel to $recipient',
        detail: parcel.stage == SendStage.delivered
            ? 'Delivered'
            : 'Demo courier on the way',
        location: AppRoutes.sendTracking,
        actionLabel: 'Track',
      );
    case SendStage.receipt:
      return null;
  }
}
