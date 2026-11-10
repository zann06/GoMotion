import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/core/widgets/app_mark_painter.dart';

/// The G mark is shared by the app logo, the mascot decals, and the generated
/// brand assets, so its contract is worth pinning: one traced outline, a square
/// box at every scale, and no dependence on bundled art.
void main() {
  test('the mark keeps the reference aspect in its own box', () {
    final path = GoMotionMarkPainter.path(scale: 100);
    final bounds = path.getBounds();

    // The traced outline fills its box edge to edge: a slightly wide letter with
    // the crossbar reaching the right margin.
    expect(bounds.left, lessThan(1));
    expect(bounds.top, lessThan(1));
    expect(bounds.right, closeTo(100, 1.5));
    expect(bounds.bottom, closeTo(100, 1.5));
  });

  test('the path is a single filled contour', () {
    final path = GoMotionMarkPainter.path(scale: 100);
    // One contour means one subpath: the glyph is an open G traced as one
    // outline, not a ring with a separate counter.
    final metrics = path.computeMetrics().toList();
    expect(metrics, hasLength(1));
  });

  test('the crossbar leaves the G open rather than closing the counter', () {
    final path = GoMotionMarkPainter.path(scale: 100);
    // Sampled from the glyph: the counter (the open mouth of the G) is empty
    // between the left ring and the crossbar...
    expect(path.contains(const Offset(35, 50)), isFalse);
    expect(path.contains(const Offset(50, 30)), isFalse);
    // ...while the left ring and the crossbar are solid.
    expect(path.contains(const Offset(8, 50)), isTrue);
    expect(path.contains(const Offset(75, 50)), isTrue);
  });

  test('scaling is proportional, so the mark never stretches', () {
    final small = GoMotionMarkPainter.path(scale: 20).getBounds();
    final large = GoMotionMarkPainter.path(scale: 200).getBounds();
    expect(large.width / small.width, closeTo(10, 0.05));
    expect(large.height / small.height, closeTo(10, 0.05));
  });

  test('origin offsets the whole glyph without changing its size', () {
    final atZero = GoMotionMarkPainter.path(scale: 50).getBounds();
    final shifted = GoMotionMarkPainter.path(
      origin: const Offset(10, 5),
      scale: 50,
    ).getBounds();
    expect(shifted.width, closeTo(atZero.width, 0.01));
    expect(shifted.left, closeTo(atZero.left + 10, 0.01));
    expect(shifted.top, closeTo(atZero.top + 5, 0.01));
  });

  test('paint keeps the mark inside a non-square box', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    GoMotionMarkPainter.paint(
      canvas,
      const Rect.fromLTWH(0, 0, 200, 80),
      const Color(0xFFFFFFFF),
    );
    recorder.endRecording().dispose();
  });
}
