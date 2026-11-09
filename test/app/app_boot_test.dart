import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/core/navigation/app_routes.dart';
import 'package:gomotion/core/widgets/app_bottom_nav.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps the real app with deterministic overrides.
  Future<void> pumpApp(WidgetTester tester, {String? initialLocation}) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(
            InMemoryPreferencesStore(),
          ),
          simulationClockProvider.overrideWithValue(FakeSimulationClock()),
        ],
        child: GoMotionApp(initialLocation: initialLocation),
      ),
    );
    // Let the async fixture load resolve and the entrance animations finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('boots to the home screen with the brand greeting', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.textContaining('Good'), findsWidgets);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  // Regression: the Scaffold lays the bottom bar out with loose full-height
  // constraints. A flex child defaulting to `MainAxisSize.max` made the nav
  // grow to the full viewport and collapse every page body to zero height, so
  // the dashboard rendered blank with only the bar (vertically centred).
  testWidgets(
    'the bottom navigation stays compact and leaves room for the body',
    (tester) async {
      await pumpApp(tester);

      final nav = tester.getRect(find.byType(AppBottomNav));
      expect(nav.height, lessThan(120), reason: 'nav must size to its content');
      // Pinned to the bottom, not centred in the viewport.
      expect(nav.top, greaterThan(600));

      final greeting = tester.getRect(find.textContaining('Good').first);
      expect(greeting.top, greaterThanOrEqualTo(0));
      expect(
        greeting.top,
        lessThan(nav.top),
        reason: 'body must render above nav',
      );

      final card = tester.getRect(find.text('Your next journey'));
      expect(card.height, greaterThan(0));
      expect(card.top, lessThan(nav.top));
    },
  );

  testWidgets('home shows the destination entry point', (tester) async {
    await pumpApp(tester);

    expect(find.text('Your next journey'), findsOneWidget);
    expect(find.text('Search destination'), findsOneWidget);
  });

  testWidgets('home shows the demo map label rather than a real map', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('DEMO MAP'), findsWidgets);
  });

  testWidgets('bottom navigation switches between primary destinations', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Your activity'), findsOneWidget);

    await tester.tap(find.text('Rewards'));
    await tester.pumpAndSettle();
    expect(find.text('Rewards'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('service shortcuts are present and tappable', (tester) async {
    await pumpApp(tester);

    expect(find.text('Explore services'), findsOneWidget);
    expect(find.text('Ride'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('first launch welcomes the user and continues to home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final preferences = InMemoryPreferencesStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesStoreProvider.overrideWithValue(preferences),
          simulationClockProvider.overrideWithValue(FakeSimulationClock()),
        ],
        child: const GoMotionApp(initialLocation: AppRoutes.onboarding),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore the demo'), findsOneWidget);
    expect(find.text('Works fully offline'), findsOneWidget);
    expect(preferences.hasSeenOnboarding, isFalse);

    await tester.tap(find.text('Explore the demo'));
    await tester.pumpAndSettle();

    expect(find.text('Your next journey'), findsOneWidget);
    expect(preferences.hasSeenOnboarding, isTrue);
    expect(find.text('Explore the demo'), findsNothing);
  });
}
