import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/widgets/app_motion.dart';

/// Motion primitive checks.
///
/// Two properties matter here and nowhere else:
///
/// 1. Nothing in `app_motion.dart` may hold a ticker open. Every effect is a
///    finite one-shot, so a screen always reaches a stable frame.
/// 2. Reduced motion may never hide content or disable a control. The tap must
///    still fire and the child must still be there on the first frame.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMotion(
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

  Finder insideReveal(Type type) =>
      find.descendant(of: find.byType(AppReveal), matching: find.byType(type));

  double revealOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(insideReveal(FadeTransition).first)
      .opacity
      .value;

  testWidgets('AppReveal animates once and releases its ticker', (
    tester,
  ) async {
    await pumpMotion(tester, const AppReveal(child: Text('Home')));

    expect(find.text('Home'), findsOneWidget);

    // Mid-flight the content is already on screen, just still fading up.
    await tester.pump(const Duration(milliseconds: 60));
    expect(revealOpacity(tester), greaterThan(0));
    expect(revealOpacity(tester), lessThan(1));

    await tester.pumpAndSettle();

    expect(revealOpacity(tester), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a staggered AppReveal still lands fully visible', (
    tester,
  ) async {
    await pumpMotion(tester, const AppReveal(index: 5, child: Text('Late')));

    await tester.pumpAndSettle();

    expect(find.text('Late'), findsOneWidget);
    expect(revealOpacity(tester), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('AppReveal shows its child immediately under reduced motion', (
    tester,
  ) async {
    await pumpMotion(
      tester,
      const AppReveal(child: Text('Home')),
      reduceMotion: true,
    );
    // One frame only: no entrance animation may be pending.
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(insideReveal(FadeTransition), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('AppPressFeedback fires exactly once per tap', (tester) async {
    var taps = 0;
    await pumpMotion(
      tester,
      AppPressFeedback(
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 80),
      ),
    );

    await tester.tap(find.byType(AppPressFeedback));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppPressFeedback ignores a cancelled press', (tester) async {
    var taps = 0;
    await pumpMotion(
      tester,
      AppPressFeedback(
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 80),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppPressFeedback)),
    );
    await tester.pump();
    // A press is visible while held, and dragging away is a scroll, not a tap.
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      lessThan(1),
    );
    await gesture.moveBy(const Offset(0, 240));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 0);
  });

  testWidgets('AppPressFeedback still fires with motion reduced', (
    tester,
  ) async {
    var taps = 0;
    await pumpMotion(
      tester,
      AppPressFeedback(
        onTap: () => taps++,
        child: const SizedBox(width: 200, height: 80),
      ),
      reduceMotion: true,
    );

    await tester.tap(find.byType(AppPressFeedback));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('AppProgressBar eases to the new value and reports it', (
    tester,
  ) async {
    await pumpMotion(
      tester,
      const SizedBox(
        width: 200,
        child: AppProgressBar(value: 0, semanticLabel: 'Trip progress'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      0,
    );

    // Same widget position, new target: the bar tweens rather than jumping.
    await pumpMotion(
      tester,
      const SizedBox(
        width: 200,
        child: AppProgressBar(value: 0.75, semanticLabel: 'Trip progress'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      closeTo(0.75, 0.001),
    );
    expect(
      tester.getSemantics(find.byType(AppProgressBar)).value,
      '75 percent',
    );
  });

  testWidgets('AppProgressBar clamps out-of-range values', (tester) async {
    await pumpMotion(
      tester,
      const SizedBox(width: 200, child: AppProgressBar(value: 4)),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor,
      1,
    );
  });

  testWidgets('AppAnimatedCounter lands on the final value', (tester) async {
    await pumpMotion(
      tester,
      AppAnimatedCounter(value: 42, format: (value) => '${value.round()}%'),
    );
    await tester.pumpAndSettle();

    expect(find.text('42%'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AppAnimatedCounter)).label, '42%');
  });
}
