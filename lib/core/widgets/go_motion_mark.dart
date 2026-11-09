import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The GoMotion brand mark: a forward chevron inside an orbit arc.
///
/// Drawn with a [CustomPainter] rather than a bundled bitmap so it stays crisp
/// at every density and can recolour for on-gradient surfaces.
class GoMotionMark extends StatelessWidget {
  const GoMotionMark({
    this.size = 40,
    this.color = AppColors.white,
    this.background = true,
    super.key,
  });

  /// Edge length of the square mark.
  final double size;

  /// Stroke colour of the glyph.
  final Color color;

  /// Whether to paint the rounded indigo tile behind the glyph.
  final bool background;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(color: color),
    );
    if (!background) return mark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Padding(padding: EdgeInsets.all(size * 0.16), child: mark),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.36;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Orbit arc opened on the left, implying forward motion.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -0.72,
      5.0,
      false,
      paint,
    );

    final chevron = Path()
      ..moveTo(c.dx - r * 0.36, c.dy - r * 0.5)
      ..lineTo(c.dx + r * 0.4, c.dy)
      ..lineTo(c.dx - r * 0.36, c.dy + r * 0.5);
    canvas.drawPath(chevron, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
