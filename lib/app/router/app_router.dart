import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/activity/presentation/screens/activity_detail_screen.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/destination/presentation/screens/destination_search_screen.dart';
import '../../features/food/presentation/screens/food_browse_screen.dart';
import '../../features/food/presentation/screens/food_cart_screen.dart';
import '../../features/food/presentation/screens/food_checkout_screen.dart';
import '../../features/food/presentation/screens/food_receipt_screen.dart';
import '../../features/food/presentation/screens/food_restaurant_screen.dart';
import '../../features/food/presentation/screens/food_tracking_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/saved_places_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/ride/presentation/screens/ride_matching_screen.dart';
import '../../features/ride/presentation/screens/ride_payment_screen.dart';
import '../../features/ride/presentation/screens/ride_receipt_screen.dart';
import '../../features/ride/presentation/screens/ride_review_screen.dart';
import '../../features/ride/presentation/screens/ride_tracking_screen.dart';
import '../../features/ride/presentation/screens/vehicle_selection_screen.dart';
import '../../features/send/presentation/screens/send_receipt_screen.dart';
import '../../features/send/presentation/screens/send_review_screen.dart';
import '../../features/send/presentation/screens/send_screen.dart';
import '../../features/send/presentation/screens/send_tracking_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../router/app_shell.dart';

/// Builds the GoMotion [GoRouter] configuration.
///
/// Phase 0/1 establishes the shell, the four primary destinations, and the
/// error routes. Flow routes are added phase by phase; each addition must also
/// add its redirect guard here so deep links cannot bypass lifecycle checks.
GoRouter buildRouter({
  String initialLocation = AppRoutes.home,
  List<NavigatorObserver> observers = const [],
}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    observers: observers,
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(shell: navigationShell),
        branches: [
          // Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                name: AppRoutes.activityName,
                builder: (context, state) => const ActivityScreen(),
                routes: [
                  // Nested so the detail keeps the tab bar and its own stack.
                  GoRoute(
                    path: ':activityId',
                    name: AppRoutes.activityDetailName,
                    builder: (context, state) => ActivityDetailScreen(
                      activityId: state.pathParameters['activityId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Rewards
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.rewards,
                name: AppRoutes.rewardsName,
                builder: (context, state) => const RewardsScreen(),
              ),
            ],
          ),
          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: AppRoutes.profileName,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Full-screen flows live outside the shell so their own headers and
      // sticky footers own the layout.
      GoRoute(
        path: AppRoutes.destinationSearch,
        name: AppRoutes.destinationSearchName,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] == 'pickup'
              ? DestinationMode.pickup
              : DestinationMode.destination;
          return DestinationSearchScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.vehicleSelection,
        name: AppRoutes.vehicleSelectionName,
        builder: (context, state) => const VehicleSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideReview,
        name: AppRoutes.rideReviewName,
        builder: (context, state) => const RideReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideMatching,
        name: AppRoutes.rideMatchingName,
        builder: (context, state) => const RideMatchingScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideTracking,
        name: AppRoutes.rideTrackingName,
        builder: (context, state) => const RideTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.ridePayment,
        name: AppRoutes.ridePaymentName,
        builder: (context, state) => const RidePaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.rideReceipt,
        name: AppRoutes.rideReceiptName,
        builder: (context, state) => const RideReceiptScreen(),
      ),
      // GoFood
      GoRoute(
        path: AppRoutes.food,
        name: AppRoutes.foodName,
        builder: (context, state) => const FoodBrowseScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodRestaurant,
        name: AppRoutes.foodRestaurantName,
        builder: (context, state) => FoodRestaurantScreen(
          restaurantId: state.pathParameters['restaurantId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.foodCart,
        name: AppRoutes.foodCartName,
        builder: (context, state) => const FoodCartScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodCheckout,
        name: AppRoutes.foodCheckoutName,
        builder: (context, state) => const FoodCheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodTracking,
        name: AppRoutes.foodTrackingName,
        builder: (context, state) => const FoodTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodReceipt,
        name: AppRoutes.foodReceiptName,
        builder: (context, state) => const FoodReceiptScreen(),
      ),
      // GoSend
      GoRoute(
        path: AppRoutes.send,
        name: AppRoutes.sendName,
        builder: (context, state) => const SendScreen(),
      ),
      GoRoute(
        path: AppRoutes.sendReview,
        name: AppRoutes.sendReviewName,
        builder: (context, state) => const SendReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.sendTracking,
        name: AppRoutes.sendTrackingName,
        builder: (context, state) => const SendTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.sendReceipt,
        name: AppRoutes.sendReceiptName,
        builder: (context, state) => const SendReceiptScreen(),
      ),
      // Profile, rewards, and settings surfaces.
      GoRoute(
        path: AppRoutes.savedPlaces,
        name: AppRoutes.savedPlacesName,
        builder: (context, state) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: AppRoutes.aboutName,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        _RouteNotFoundScreen(location: state.uri.toString()),
  );
}

/// A recoverable not-found state for unknown or stale routes.
class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_outlined, size: 40),
                const SizedBox(height: 12),
                const Text(
                  'That screen is not available',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'The simulated journey you followed no longer exists.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
