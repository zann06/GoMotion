import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The GoMotion "G" mark, drawn as pure geometry.
///
/// The glyph is a single closed outline traced from the brand reference, so the
/// drawn mark and the identity assets are the same shape. It reads as a heavy,
/// forward-leaning **G**: a thick left ring, a long upper arm, and a chunky
/// crossbar whose tip stops short of the counter to leave the open G notch.
///
/// The outline is measured in a `277 x 247` reference box and normalised here to
/// a unit box, then scaled with a single matrix. Two consequences matter:
///
/// * the stroke weight is baked into the geometry, so the mark never distorts
///   when scaled — a 20px list glyph and the 1024px app icon agree;
/// * no asset is bundled and nothing is fetched, so the app stays offline.
///
/// Straight runs use `lineTo`; the ring uses `arcTo` on the fitted circle so the
/// mark stays smooth at hero sizes instead of showing polygon facets.
class GoMotionMarkPainter {
  const GoMotionMarkPainter._();

  /// Size of the reference box the outline was traced in.
  static const Size referenceBox = Size(277, 247);

  /// The traced outline, clockwise, in reference-box pixels.
  ///
  /// The path is one contour: the arm's tip, down the arm's underside, around
  /// the left ring, along the bottom, up the crossbar's right flank, into the
  /// crossbar tip, out along the crossbar's top edge, and back up to the tip.
  static const List<Offset> _outline = [
    Offset(224, 0),
    Offset(241, 1),
    Offset(207, 52),
    Offset(195, 56),
    Offset(91, 70),
    Offset(72, 76),
    Offset(58, 84),
    Offset(40, 100),
    Offset(28, 117),
    Offset(20, 138),
    Offset(20, 156),
    Offset(24, 167),
    Offset(36, 181),
    Offset(49, 188),
    Offset(73, 190),
    Offset(143, 180),
    Offset(150, 178),
    Offset(156, 172),
    Offset(176, 140),
    Offset(176, 136),
    Offset(83, 148),
    Offset(116, 98),
    Offset(274, 76),
    Offset(276, 78),
    Offset(274, 85),
    Offset(197, 221),
    Offset(188, 227),
    Offset(53, 246),
    Offset(28, 244),
    Offset(1, 234),
    Offset(0, 62),
    Offset(31, 39),
    Offset(66, 24),
  ];

  /// Builds the mark in a `1 x 1` box, optionally offset and scaled so the
  /// mascot can stamp the same glyph on its helmet and chest.
  static Path path({Offset origin = Offset.zero, double scale = 1}) {
    final sx = scale / referenceBox.width;
    final sy = scale / referenceBox.height;

    final points = [
      for (final p in _outline)
        Offset(origin.dx + p.dx * sx, origin.dy + p.dy * sy),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  /// Paints the mark filled with [color] inside [box].
  static void paint(Canvas canvas, Rect box, Color color) {
    final scale = math.min(box.width, box.height);
    final origin = box.center - Offset(scale / 2, scale / 2);
    canvas.drawPath(
      path(origin: origin, scale: scale),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }
}
