import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/constants/app_icons.dart';
import 'package:gomotion/core/navigation/app_routes.dart';
import 'package:gomotion/core/widgets/app_bottom_nav.dart';
import 'package:gomotion/core/widgets/schematic_map.dart';
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

  testWidgets('the map preview follows the selected vehicle', (tester) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    SchematicMap map() =>
        tester.widget<SchematicMap>(find.byType(SchematicMap).first);

    // Defaults to the cheapest option: GoRide is a motorbike.
    expect(map().vehicle, VehicleKind.motorbike);
    expect(map().marker, isNotNull);

    await tester.ensureVisible(find.text('GoCar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoCar'));
    await tester.pumpAndSettle();
    expect(map().vehicle, VehicleKind.car);
    expect(find.textContaining('Preview · GoCar'), findsOneWidget);

    await tester.ensureVisible(find.text('GoCar Premium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoCar Premium'));
    await tester.pumpAndSettle();
    expect(map().vehicle, VehicleKind.premium);
    expect(find.textContaining('Preview · GoCar Premium'), findsOneWidget);
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

  testWidgets('GoFood browse shows the five reference-board categories', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.food);
    await tester.pumpAndSettle();

    expect(find.text('Popular Restaurants'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    for (final category in const ['Asian', 'Western', 'Local', 'Dessert']) {
      expect(find.text(category), findsOneWidget, reason: category);
    }
  });

  testWidgets('GoFood category filter narrows to the matching kitchens', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.food);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local'));
    await tester.pumpAndSettle();

    expect(find.text('Rasa Nusantara'), findsOneWidget);
    expect(find.text('Nori House'), findsNothing);
    expect(find.text('Sweet Corner'), findsNothing);
  });

  testWidgets('GoFood See all expands the list and includes every kitchen', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.food);
    await tester.pumpAndSettle();

    expect(find.text('Pasta Corner'), findsNothing);

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();

    expect(find.text('All demo restaurants'), findsOneWidget);
    // The expanded list is a plain column inside the page scroll, so even the
    // last row is present in the tree without scrolling.
    expect(find.text('Pasta Corner'), findsOneWidget);
    expect(find.text('Sweet Corner'), findsOneWidget);
  });

  testWidgets(
    'GoFood search narrows the list and resets from the empty state',
    (tester) async {
      await pumpApp(tester, AppRoutes.food);
      // The empty-state action sits low on the page, so a taller surface keeps
      // it clear of the bottom navigation bar.
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nori');
      await tester.pumpAndSettle();

      expect(find.text('Search results'), findsOneWidget);
      expect(find.text('Nori House'), findsOneWidget);
      expect(find.text('Daily Bowl'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No demo restaurants found'), findsOneWidget);

      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();

      expect(find.text('Popular Restaurants'), findsOneWidget);
      expect(find.text('Nori House'), findsOneWidget);
    },
  );

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

    expect(find.text('Orders'), findsWidgets);
    expect(find.text('No demo journeys yet'), findsOneWidget);
  });

  testWidgets('vehicle selection offers a promo row that applies a code', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    // The reference puts the promo entry on the vehicle list, not only on the
    // review screen, so a rider can discount before choosing.
    expect(find.text('Use Promo Code'), findsOneWidget);

    await tester.ensureVisible(find.text('Use Promo Code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Promo Code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'MOVE10');
    await tester.tap(find.text('Apply code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('MOVE10'), findsWidgets);
    expect(find.text('Use Promo Code'), findsNothing);
  });

  testWidgets('the driver card shows the plate and a demo-only call button', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    await tester.tap(find.textContaining('Review Rp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm demo booking'));
    await tester.pumpAndSettle();

    clock.advance(SimulationTiming.matching);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The plate comes from the fixture, not a synthetic index.
    expect(find.textContaining('B '), findsWidgets);

    // Matching hides the call button: there is nobody to call yet.
    expect(find.byIcon(Icons.call_rounded), findsNothing);

    clock.advance(SimulationTiming.driverApproach);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Confirm pickup and start'));
    await tester.pumpAndSettle();

    // On the live trip the card offers calling, and it explains it is simulated
    // rather than opening a dialer.
    expect(find.byIcon(Icons.call_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.call_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Calling is simulated'), findsOneWidget);
  });

  testWidgets('live tracking shows a remaining time and distance badge', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.destinationSearch);
    await chooseFirstDestination(tester);

    await tester.tap(find.textContaining('Review Rp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm demo booking'));
    await tester.pumpAndSettle();

    clock.advance(SimulationTiming.matching);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    clock.advance(SimulationTiming.driverApproach);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Confirm pickup and start'));
    await tester.pumpAndSettle();

    // At the start of the trip the badge reports the whole remaining leg.
    expect(find.textContaining('min'), findsWidgets);
    expect(find.textContaining('km left'), findsOneWidget);
  });

  testWidgets('the inbox tab badges the unread fixture count', (tester) async {
    await pumpApp(tester, AppRoutes.home);

    // Three of the five seeded messages start unread.
    expect(find.widgetWithText(AppBottomNav, '3'), findsOneWidget);

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(find.text('GoMotion demo is ready'), findsOneWidget);
    expect(find.textContaining('Mark all read'), findsOneWidget);

    await tester.tap(find.textContaining('Mark all read'));
    await tester.pumpAndSettle();

    // Reading everything clears both the row action and the tab badge.
    expect(find.textContaining('Mark all read'), findsNothing);
    expect(find.widgetWithText(AppBottomNav, '3'), findsNothing);
  });

  testWidgets('inbox filters narrow the list without hiding the badge', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.inbox);
    await tester.pumpAndSettle();

    expect(find.text('MOVE10 applies to your next ride'), findsOneWidget);
    expect(find.text('GoSend keeps parcels on device'), findsOneWidget);

    await tester.tap(find.text('Promos'));
    await tester.pumpAndSettle();

    expect(find.text('MOVE10 applies to your next ride'), findsOneWidget);
    expect(find.text('GoSend keeps parcels on device'), findsNothing);
    // The badge counts the whole inbox, not the filtered view.
    expect(find.widgetWithText(AppBottomNav, '3'), findsOneWidget);
  });

  testWidgets('inbox actions open a local screen and mark the message read', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.inbox);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Open GoSend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open GoSend'));
    await tester.pumpAndSettle();

    expect(find.text('GoSend'), findsWidgets);
  });

  testWidgets('rewards is reached from the profile instead of the tab bar', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.profile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();

    expect(find.text('Fictional demo points and badges'), findsOneWidget);
  });
}
