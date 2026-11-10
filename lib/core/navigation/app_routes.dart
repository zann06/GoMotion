/// Canonical route paths and names, mirroring `docs/ROUTING_SPECIFICATION.md`.
///
/// Keeping these in one place prevents stringly-typed navigation from drifting
/// and makes redirect guards readable.
abstract final class AppRoutes {
  // Primary shell destinations.
  static const String home = '/';
  static const String homeName = 'home';

  static const String activity = '/activity';
  static const String activityName = 'activity';

  /// The simulated inbox tab.
  static const String inbox = '/inbox';
  static const String inboxName = 'inbox';

  static const String rewards = '/rewards';
  static const String rewardsName = 'rewards';

  static const String profile = '/profile';
  static const String profileName = 'profile';

  // Onboarding.
  static const String onboarding = '/welcome';
  static const String onboardingName = 'onboarding';

  // Splash.
  static const String splash = '/splash';
  static const String splashName = 'splash';

  // Destination selection.
  static const String destinationSearch = '/destination/search';
  static const String destinationSearchName = 'destinationSearch';

  // Ride flow.
  static const String vehicleSelection = '/ride/vehicle';
  static const String vehicleSelectionName = 'vehicleSelection';

  static const String rideReview = '/ride/review';
  static const String rideReviewName = 'rideReview';

  static const String rideMatching = '/ride/matching';
  static const String rideMatchingName = 'rideMatching';

  static const String rideTracking = '/ride/tracking';
  static const String rideTrackingName = 'rideTracking';

  static const String ridePayment = '/ride/payment';
  static const String ridePaymentName = 'ridePayment';

  static const String rideReceipt = '/ride/receipt';
  static const String rideReceiptName = 'rideReceipt';

  // GoFood.
  static const String food = '/food';
  static const String foodName = 'food';

  static const String foodRestaurant = '/food/restaurant/:restaurantId';
  static const String foodRestaurantName = 'foodRestaurant';

  static const String foodCart = '/food/cart';
  static const String foodCartName = 'foodCart';

  static const String foodCheckout = '/food/checkout';
  static const String foodCheckoutName = 'foodCheckout';

  static const String foodTracking = '/food/tracking';
  static const String foodTrackingName = 'foodTracking';

  static const String foodReceipt = '/food/receipt';
  static const String foodReceiptName = 'foodReceipt';

  // GoSend.
  static const String send = '/send';
  static const String sendName = 'send';

  static const String sendReview = '/send/review';
  static const String sendReviewName = 'sendReview';

  static const String sendTracking = '/send/tracking';
  static const String sendTrackingName = 'sendTracking';

  static const String sendReceipt = '/send/receipt';
  static const String sendReceiptName = 'sendReceipt';

  // Activity detail.
  static const String activityDetail = '/activity/:activityId';
  static const String activityDetailName = 'activityDetail';

  // Settings and about.
  static const String settings = '/settings';
  static const String settingsName = 'settings';

  static const String about = '/about';
  static const String aboutName = 'about';

  static const String savedPlaces = '/profile/places';
  static const String savedPlacesName = 'savedPlaces';

  /// Builds a restaurant detail path for [restaurantId].
  static String foodRestaurantPath(String restaurantId) =>
      '/food/restaurant/$restaurantId';

  /// Builds an activity detail path for [activityId].
  static String activityDetailPath(String activityId) =>
      '/activity/$activityId';
}

/// Tab indices of the primary shell destinations, in display order.
///
/// Matches the reference board: Home, Food, Orders, Inbox, Profile. Rewards is
/// still a route, but it is reached from Profile rather than from the bar.
abstract final class ShellTab {
  static const int home = 0;
  static const int food = 1;
  static const int orders = 2;
  static const int inbox = 3;
  static const int profile = 4;
}
