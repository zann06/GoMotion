import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/constants/mascot_assets.dart';
import 'package:gomotion/core/widgets/mascot.dart';
import 'package:gomotion/core/widgets/mascot_map_marker.dart';

/// Mascot component checks.
///
/// Every pose is a finite one-shot animation, so these tests assert that the
/// character settles into a stable, visible frame and never leaves a running
/// ticker behind — the property that keeps the tracking screen at frame rate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMascot(
    WidgetTester tester,
    Widget child, {
    bool reduceMotion = false,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (reduceMotion) {
      container.read(inAppReduceMotionProvider.notifier).set(true);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  test('every mascot pose has an asset slot', () {
    for (final variant in MascotVariant.values) {
      expect(MascotAssets.files[variant], isNotNull);
      expect(MascotAssets.files[variant], startsWith(MascotAssets.directory));
    }
    // Code-drawn until bitmaps are dropped in, so no file is requested yet.
    expect(MascotAssets.bundled, isFalse);
    expect(MascotAssets.fileFor(MascotVariant.hero), isNull);
  });

  test('ride categories map to the matching pose', () {
    expect(MascotVariant.forRideCategory('GoRide'), MascotVariant.ride);
    expect(MascotVariant.forRideCategory('GoCar'), MascotVariant.car);
    expect(MascotVariant.forRideCategory('GoCar Premium'), MascotVariant.car);
    expect(MascotVariant.forRideCategory(null), MascotVariant.car);
  });

  for (final variant in MascotVariant.values) {
    testWidgets('${variant.name} renders and settles', (tester) async {
      await pumpMascot(tester, Mascot(variant: variant));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Mascot), findsOneWidget);
      final semantics = tester.getSemantics(find.byType(Mascot));
      expect(semantics.label, isNotEmpty);
    });
  }

  testWidgets('reduced motion settles without animating', (tester) async {
    await pumpMascot(
      tester,
      const Mascot(variant: MascotVariant.wave),
      reduceMotion: true,
    );
    // A single pump is enough: the controller starts at its settled value.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Mascot), findsOneWidget);
  });

  testWidgets('loading dots respect reduced motion', (tester) async {
    await pumpMascot(tester, const MascotLoadingDots(), reduceMotion: true);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('banner shows its copy beside the mascot', (tester) async {
    await pumpMascot(
      tester,
      const MascotBanner(
        variant: MascotVariant.food,
        title: 'Hungry? The demo kitchen is open',
        message: 'Every price is fictional demo data.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hungry? The demo kitchen is open'), findsOneWidget);
    expect(find.text('Every price is fictional demo data.'), findsOneWidget);
    expect(find.byType(Mascot), findsOneWidget);
  });

  testWidgets('map marker reports a simulated position', (tester) async {
    await pumpMascot(
      tester,
      const MascotMapMarker(
        variant: MascotVariant.ride,
        bearing: 1.2,
        isMoving: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final semantics = tester.getSemantics(find.byType(MascotMapMarker));
    expect(semantics.label, contains('simulated'));
  });

  testWidgets('map marker fits inside its declared footprint', (tester) async {
    const size = 54.0;
    await pumpMascot(
      tester,
      const SizedBox(
        width: 120,
        height: 120,
        child: MascotMapMarker(variant: MascotVariant.car, size: size),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(MascotMapMarker.boxSize(size), size + MascotMapMarker.margin * 2);
  });
}
