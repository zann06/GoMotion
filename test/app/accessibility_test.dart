import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/navigation/app_routes.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

/// Accessibility and layout-robustness checks.
///
/// These are deliberately hostile: reduced motion on, and a raised text scale,
/// so any overflow or motion regression fails the suite rather than reaching a
/// device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const routes = <String>[
    AppRoutes.splash,
    AppRoutes.home,
    AppRoutes.onboarding,
    AppRoutes.destinationSearch,
    AppRoutes.activity,
    AppRoutes.rewards,
    AppRoutes.profile,
    AppRoutes.savedPlaces,
    AppRoutes.settings,
    AppRoutes.about,
    AppRoutes.food,
    '/food/restaurant/rest_nori',
    AppRoutes.send,
    AppRoutes.vehicleSelection,
    AppRoutes.rideReview,
  ];

  Future<ProviderContainer> pumpRoute(
    WidgetTester tester,
    String location, {
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          InMemoryPreferencesStore(hasSeenOnboarding: true),
        ),
        simulationClockProvider.overrideWithValue(FakeSimulationClock()),
      ],
    );
    addTearDown(container.dispose);
    container.read(inAppReduceMotionProvider.notifier).set(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: GoMotionApp(initialLocation: location),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    return container;
  }

  for (final route in routes) {
    testWidgets('$route renders without overflow at 1.0x text', (tester) async {
      await pumpRoute(tester, route);
      expect(tester.takeException(), isNull);
    });
  }

  for (final route in routes) {
    testWidgets('$route renders without overflow at 1.3x text', (tester) async {
      await pumpRoute(tester, route, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }
}
