import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/app.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

/// Guards the reduced-motion path for decorative entrance animations.
///
/// The home "Your next journey" card used to drive its fade from a controller
/// parked at 0 when motion was reduced, leaving the card permanently invisible.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home journey card stays visible under reduced motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        child: const GoMotionApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final title = find.text('Your next journey');
    expect(title, findsOneWidget);

    // Every fade between the card and the root must remain fully opaque.
    var opacity = 1.0;
    for (final fade in tester.widgetList<FadeTransition>(
      find.ancestor(of: title, matching: find.byType(FadeTransition)),
    )) {
      opacity *= fade.opacity.value;
    }
    expect(opacity, 1.0);
  });
}
