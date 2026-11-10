import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/constants/app_colors.dart';
import 'package:gomotion/core/widgets/app_logo.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';

/// The mark is geometry, not an asset, so these checks pin the contract that
/// every call site relies on: one widget, no bundled art, and a label only when
/// the mark carries meaning.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AppLogoMark draws without a bundled asset', (tester) async {
    await pump(tester, const AppLogoMark(size: 40, semanticLabel: 'logo'));

    final paint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(AppLogoMark),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(paint.painter, isNotNull);
    expect(find.bySemanticsLabel('logo'), findsOneWidget);
  });

  testWidgets('AppLogoMark is decorative by default', (tester) async {
    await pump(tester, const AppLogoMark(size: 24));
    expect(
      find.descendant(
        of: find.byType(AppLogoMark),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });

  testWidgets('AppLogoChip carries the brand gradient', (tester) async {
    await pump(tester, const AppLogoChip(size: 44));

    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppLogoChip),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.gradient, AppColors.primaryGradient);
    expect(find.byType(AppLogoMark), findsOneWidget);
  });

  testWidgets('AppBrandLockup shows the wordmark and an optional tagline', (
    tester,
  ) async {
    await pump(tester, const AppBrandLockup(markSize: 40));
    expect(find.text('GoMotion'), findsOneWidget);
    expect(find.text('Move smarter'), findsNothing);

    await pump(tester, const AppBrandLockup(markSize: 40, showTagline: true));
    expect(find.text('Move smarter'), findsOneWidget);
  });

  testWidgets('AppSplashSignature settles under reduced motion', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        // The motion preference persists through the preferences store, so the
        // container needs the same override the app bootstrap provides.
        preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      ],
    );
    addTearDown(container.dispose);
    container.read(inAppReduceMotionProvider.notifier).set(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: AppSplashSignature(size: 96))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Reduced motion renders the settled mark instead of parking it on an
    // invisible first frame.
    final opacity = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(AppSplashSignature),
        matching: find.byType(Opacity),
      ),
    );
    for (final widget in opacity) {
      expect(widget.opacity, 1.0);
    }
    expect(find.byType(AppLogoMark), findsOneWidget);
  });

  testWidgets('the mark keeps its square box at every size', (tester) async {
    for (final size in const [20.0, 32.0, 96.0]) {
      await pump(tester, AppLogoMark(size: size));
      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(AppLogoMark),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(box.width, size);
      expect(box.height, size);
    }
  });
}
