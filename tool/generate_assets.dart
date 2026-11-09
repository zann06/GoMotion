// Tool: generates GoMotion's original local brand assets.
//
// Offline and reproducible: every asset is drawn with the Flutter canvas and
// written to `assets/images/`. No network access and no external image tooling,
// which keeps the "fully offline" product constraint honest.
//
// Run with: flutter test tool/generate_assets.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Brand tokens, mirrored from docs/DESIGN_SYSTEM.md.
const Color _indigo = Color(0xFF4F46E5);
const Color _blue = Color(0xFF2563EB);
const Color _violet = Color(0xFF8B5CF6);
const Color _navy = Color(0xFF111827);
const Color _white = Color(0xFFFFFFFF);

/// Renders [child] once in a widget test harness so goldens can be captured.
Widget _harness(Widget child, Size size) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(
        child: RepaintBoundary(
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
}

void main() {
  // Golden files are written next to the source, then moved into assets/.
  final outDir = Directory('tool/goldens');

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget child,
    Size size,
  ) async {
    await tester.pumpWidget(_harness(child, size));
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  setUpAll(() {
    if (outDir.existsSync()) {
      outDir.deleteSync(recursive: true);
    }
  });

  testWidgets('brand mark', (tester) async {
    await capture(
      tester,
      'gomotion_mark',
      const _MarkTile(),
      const Size(256, 256),
    );
  });

  testWidgets('demo user avatar', (tester) async {
    await capture(
      tester,
      'avatar_demo',
      const _AvatarTile(letter: 'A', color: _indigo),
      const Size(128, 128),
    );
  });

  testWidgets('driver avatars', (tester) async {
    await capture(
      tester,
      'driver_ari',
      const _AvatarTile(letter: 'A', color: _blue),
      const Size(128, 128),
    );
    await capture(
      tester,
      'driver_nadia',
      const _AvatarTile(letter: 'N', color: _violet),
      const Size(128, 128),
    );
    await capture(
      tester,
      'driver_raka',
      const _AvatarTile(letter: 'R', color: _navy),
      const Size(128, 128),
    );
  });

  testWidgets('restaurant tiles', (tester) async {
    await capture(
      tester,
      'nori_house',
      const _FoodTile(color: Color(0xFFE8E7FD)),
      const Size(200, 200),
    );
    await capture(
      tester,
      'daily_bowl',
      const _FoodTile(color: Color(0xFFE3F0E6)),
      const Size(200, 200),
    );
    await capture(
      tester,
      'pasta_corner',
      const _FoodTile(color: Color(0xFFFBEBDD)),
      const Size(200, 200),
    );
  });

  testWidgets('menu tiles', (tester) async {
    await capture(
      tester,
      'salmon_bowl',
      const _FoodTile(color: Color(0xFFFDE8E4)),
      const Size(160, 160),
    );
    await capture(
      tester,
      'katsu_set',
      const _FoodTile(color: Color(0xFFFBF0DC)),
      const Size(160, 160),
    );
    await capture(
      tester,
      'garden_bowl',
      const _FoodTile(color: Color(0xFFE5F2E6)),
      const Size(160, 160),
    );
    await capture(
      tester,
      'mushroom_pasta',
      const _FoodTile(color: Color(0xFFEDE7F6)),
      const Size(160, 160),
    );
  });

  testWidgets('copy goldens into assets', (tester) async {
    final target = Directory('assets/images');
    target.createSync(recursive: true);
    final files = outDir.listSync().whereType<File>().toList();
    expect(files, isNotEmpty, reason: 'No goldens were produced.');
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      file.copySync('${target.path}/$name');
    }
  });
}

/// The GoMotion mark: an indigo tile with a forward chevron and orbit arc.
class _MarkTile extends StatelessWidget {
  const _MarkTile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigo, _blue],
        ),
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.30;
    final paint = Paint()
      ..color = _white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Orbit arc, opened on the left to imply forward motion.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -0.72,
      5.0,
      false,
      paint,
    );

    // Forward chevron.
    final path = Path()
      ..moveTo(c.dx - r * 0.38, c.dy - r * 0.52)
      ..lineTo(c.dx + r * 0.42, c.dy)
      ..lineTo(c.dx - r * 0.38, c.dy + r * 0.52);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A tonal avatar tile with an initial drawn as vector paths.
///
/// Initials are painted geometrically rather than with `Text` so the generated
/// asset never depends on a font that may be absent from the build host.
class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(56, 56),
          painter: _InitialPainter(letter: letter, color: color),
        ),
      ),
    );
  }
}

/// Draws a single capital initial from simple stroke segments.
class _InitialPainter extends CustomPainter {
  const _InitialPainter({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    switch (letter) {
      case 'A':
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.08, h)
            ..lineTo(w * 0.5, 0)
            ..lineTo(w * 0.92, h),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.24, h * 0.64),
          Offset(w * 0.76, h * 0.64),
          paint,
        );
      case 'N':
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.1, h)
            ..lineTo(w * 0.1, 0)
            ..lineTo(w * 0.9, h)
            ..lineTo(w * 0.9, 0),
          paint,
        );
      case 'R':
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.12, h)
            ..lineTo(w * 0.12, 0)
            ..lineTo(w * 0.68, 0)
            ..arcToPoint(
              Offset(w * 0.68, h * 0.54),
              radius: Radius.circular(w * 0.3),
              clockwise: true,
            )
            ..lineTo(w * 0.12, h * 0.54),
          paint,
        );
        canvas.drawLine(Offset(w * 0.5, h * 0.54), Offset(w * 0.92, h), paint);
      default:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.32, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InitialPainter oldDelegate) =>
      oldDelegate.letter != letter || oldDelegate.color != color;
}

/// Abstract tonal tile used instead of photographic food imagery.
class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(72, 72),
          painter: _BowlPainter(tint: _indigo.withValues(alpha: 0.22)),
        ),
      ),
    );
  }
}

/// A restrained abstract "dish" glyph, drawn with strokes only.
class _BowlPainter extends CustomPainter {
  const _BowlPainter({required this.tint});

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    canvas.drawArc(
      Rect.fromLTWH(0, h * 0.14, w, h * 0.72),
      0,
      3.14159,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.22, h * 0.14),
      Offset(w * 0.78, h * 0.14),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.62), w * 0.16, paint);
  }

  @override
  bool shouldRepaint(covariant _BowlPainter oldDelegate) =>
      oldDelegate.tint != tint;
}
