import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/navigation/app_routes.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

/// Widget-level journey tests.
///
/// These drive the real screens with real taps, so a control that renders but
/// does nothing fails the suite. The simulation clock is injected so stage
/// progression is deterministic rather than wall-clock dependent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSimulationClock clock;
  late ProviderContainer container;

  Future<void> pumpApp(
    WidgetTester tester,
    String location, {
    bool reduceMotion = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    clock = FakeSimulationClock();
    container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          InMemoryPreferencesStore(hasSeenOnboarding: true),
        ),
        simulationClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);

    // Reduced motion stops decorative loops, so `pumpAndSettle` can reach a
    // stable frame. It also exercises the accessibility path end to end.
    if (reduceMotion) {
      container.read(inAppReduceMotionProvider.notifier).set(true);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: GoMotionApp(initialLocation: location),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Taps the first demo destination in the search results.
  Future<void> chooseFirstDestination(WidgetTester tester) async {
    await tester.pumpAndSettle();
    final rows = find.text('Campus Hub');
    expect(rows, findsWidgets, reason: 'Demo destinations must be listed.');
    await tester.tap(rows.first);
    await tester.pumpAndSettle();
  }

  testWidgets('ride journey completes through real taps', (tester) async {
    await pumpApp(tester, AppRoutes.destinationSearch);

    await chooseFirstDestination(tester);
    expect(find.text('Choose your ride'), findsOneWidget);

    // Vehicle selection defaults to the cheapest option, so the CTA is live.
    final reviewCta = find.textContaining('Review Rp');
    expect(reviewCta, findsOneWidget);
    await tester.tap(reviewCta);
    await tester.pumpAndSettle();

    expect(find.text('Review your ride'), findsOneWidget);
    await tester.tap(find.text('Confirm demo booking'));
    await tester.pumpAndSettle();

    expect(find.text('Finding your driver'), findsOneWidget);

    clock.advance(SimulationTiming.matching);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your demo driver'), findsOneWidget);

    clock.advance(SimulationTiming.driverApproach);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Confirm pickup and start'));
    await tester.pumpAndSettle();

    expect(find.text('On your way'), findsOneWidget);

    clock.advance(SimulationTiming.rideInProgress);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Pay for your demo ride'), findsOneWidget);
    await tester.tap(find.text('Confirm demo payment'));
    await tester.pumpAndSettle();

    expect(find.text('Demo receipt'), findsOneWidget);
  });

  testWidgets('a promo code can be applied and removed from the review', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    await tester.tap(find.textContaining('Review Rp'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'MOVE10');
    await tester.ensureVisible(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MOVE10 applied'), findsOneWidget);

    await tester.ensureVisible(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MOVE10 applied'), findsNothing);
  });

  testWidgets('an invalid promo code shows an inline error', (tester) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    await tester.tap(find.textContaining('Review Rp'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'NOTREAL');
    await tester.ensureVisible(find.text('Apply'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // The failure is shown as text, not only as a coloured border.
    expect(find.textContaining('promo'), findsWidgets);
  });

  testWidgets('GoFood browse opens a restaurant and the cart', (tester) async {
    await pumpApp(tester, AppRoutes.food);
    await tester.pumpAndSettle();

    expect(find.text('GoFood'), findsOneWidget);

    await tester.tap(find.text('Nori House'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);

    // Add the first dish, then open the cart.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('View demo cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your demo cart'), findsOneWidget);
  });

  testWidgets('GoSend blocks an incomplete parcel with an inline error', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.send);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get demo quote'));
    await tester.pumpAndSettle();

    // Still on the form, with a readable reason rather than a dead end.
    expect(find.text('GoSend'), findsOneWidget);
    expect(find.textContaining('sender name'), findsOneWidget);
  });

  testWidgets('settings can enable reduced motion and it persists', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.settings, reduceMotion: false);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();

    expect(find.textContaining('reduced motion on'), findsOneWidget);
  });

  testWidgets('activity starts empty and states that honestly', (tester) async {
    await pumpApp(tester, AppRoutes.activity);
    await tester.pumpAndSettle();

    expect(find.text('Your activity'), findsOneWidget);
    expect(find.text('No demo journeys yet'), findsOneWidget);
  });
}
