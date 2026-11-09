import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
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
}
