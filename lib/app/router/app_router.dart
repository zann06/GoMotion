import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../features/activity/presentation/screens/activity_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
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
