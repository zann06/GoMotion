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
import 'package:gomotion/core/widgets/app_mark_painter.dart';

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
      const _FoodTile(
        color: Color(0xFFE8E7FD),
        glyph: DishGlyph.noriBowl,
        accent: _indigo,
      ),
      const Size(200, 200),
    );
    await capture(
      tester,
      'daily_bowl',
      const _FoodTile(
        color: Color(0xFFE3F0E6),
        glyph: DishGlyph.gardenBowl,
        accent: Color(0xFF2F855A),
      ),
      const Size(200, 200),
    );
    await capture(
      tester,
      'pasta_corner',
      const _FoodTile(
        color: Color(0xFFFBEBDD),
        glyph: DishGlyph.pasta,
        accent: Color(0xFFC05621),
      ),
      const Size(200, 200),
    );
  });

  testWidgets('menu tiles', (tester) async {
    await capture(
      tester,
      'salmon_bowl',
      const _FoodTile(
        color: Color(0xFFFDE8E4),
        glyph: DishGlyph.salmonBowl,
        accent: Color(0xFFD97757),
      ),
      const Size(160, 160),
    );
    await capture(
      tester,
      'katsu_set',
      const _FoodTile(
        color: Color(0xFFFBF0DC),
        glyph: DishGlyph.katsu,
        accent: Color(0xFFB7791F),
      ),
      const Size(160, 160),
    );
    await capture(
      tester,
      'garden_bowl',
      const _FoodTile(
        color: Color(0xFFE5F2E6),
        glyph: DishGlyph.gardenBowl,
        accent: Color(0xFF2F855A),
      ),
      const Size(160, 160),
    );
    await capture(
      tester,
      'mushroom_pasta',
      const _FoodTile(
        color: Color(0xFFEDE7F6),
        glyph: DishGlyph.mushroomPasta,
        accent: Color(0xFF6B46C1),
      ),
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

/// The GoMotion mark on a brand-gradient tile.
///
/// The glyph comes from the shared [GoMotionMarkPainter], which is the same
/// geometry the in-app logo and the mascot decals use — so a generated icon can
/// never drift away from the identity the way a private copy would.
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
    // The glyph fills the tile edge to edge, like a launcher icon: 14% clear
    // space keeps it readable inside the platform's rounded mask.
    final inset = size.shortestSide * 0.14;
    GoMotionMarkPainter.paint(
      canvas,
      Rect.fromLTWH(
        (size.width - size.shortestSide) / 2 + inset,
        (size.height - size.shortestSide) / 2 + inset,
        size.shortestSide - inset * 2,
        size.shortestSide - inset * 2,
      ),
      _white,
    );
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
  const _FoodTile({
    required this.color,
    this.glyph = DishGlyph.noriBowl,
    this.accent = _indigo,
  });

  final Color color;

  /// Which dish illustration to draw, so two tiles never look identical.
  final DishGlyph glyph;

  /// Ink colour for the illustration.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _DishPainter(glyph: glyph, accent: accent),
      ),
    );
  }
}

/// The dish illustrations the food tiles can draw.
enum DishGlyph {
  /// A rice bowl with a nori sheet, salmon slice, and sesame.
  noriBowl,

  /// A green bowl of leaves and vegetable rounds.
  gardenBowl,

  /// A plate of twirled pasta with a fork.
  pasta,

  /// A rice bowl with a salmon fillet and a lemon wedge.
  salmonBowl,

  /// A tray with sliced katsu, rice, and a drizzle.
  katsu,

  /// A plate of pasta with mushroom caps.
  mushroomPasta,
}

/// A soft overhead illustration of a dish.
///
/// Everything is drawn from rounded shapes with a warm shadow underneath, so a
/// tile reads as food at a glance without photo imagery, and it stays crisp at
/// any density.
class _DishPainter extends CustomPainter {
  const _DishPainter({required this.glyph, required this.accent});

  final DishGlyph glyph;
  final Color accent;

  static const Color _nori = Color(0xFF26333F);
  static const Color _rice = Color(0xFFFDFCF7);
  static const Color _shadow = Color(0x22212D3F);
  static const Color _salmon = Color(0xFFF08A6B);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);

    // Ambient shadow so the dish sits on the tile rather than floating.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.72),
        width: 0.68,
        height: 0.16,
      ),
      Paint()..color = _shadow,
    );

    switch (glyph) {
      case DishGlyph.noriBowl:
        _bowl(canvas, fill: _rice, rim: accent.withValues(alpha: 0.30));
        // A folded nori sheet, tilted like it was just laid on the rice.
        canvas.save();
        canvas.translate(0.375, 0.435);
        canvas.rotate(-0.16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.075, -0.115, 0.15, 0.23),
            const Radius.circular(0.018),
          ),
          Paint()..color = _nori,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.062, -0.100, 0.045, 0.20),
            const Radius.circular(0.014),
          ),
          Paint()..color = _nori.withValues(alpha: 0.55),
        );
        canvas.restore();
        // Salmon slice and two sesame seeds balance the composition.
        _pill(canvas, const Offset(0.575, 0.415), 0.155, 0.070, -0.32, _salmon);
        _pill(
          canvas,
          const Offset(0.612, 0.462),
          0.120,
          0.048,
          -0.32,
          _salmon.withValues(alpha: 0.78),
        );
        for (final centre in const [
          Offset(0.505, 0.352),
          Offset(0.560, 0.500),
        ]) {
          canvas.drawCircle(centre, 0.016, Paint()..color = _rice);
        }
        break;
      case DishGlyph.gardenBowl:
        _bowl(canvas, fill: _rice, rim: accent.withValues(alpha: 0.34));
        // Leaves: three teardrops fanned out of the bowl.
        for (final (cx, cy, rot, scale) in const [
          (0.435, 0.395, -0.5, 1.0),
          (0.520, 0.372, 0.10, 1.12),
          (0.598, 0.402, 0.62, 0.94),
        ]) {
          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(rot);
          canvas.scale(scale);
          final leaf = Path()
            ..moveTo(0, -0.085)
            ..quadraticBezierTo(0.070, -0.030, 0, 0.075)
            ..quadraticBezierTo(-0.070, -0.030, 0, -0.085)
            ..close();
          canvas.drawPath(
            leaf,
            Paint()..color = accent.withValues(alpha: 0.55),
          );
          canvas.drawLine(
            const Offset(0, -0.060),
            const Offset(0, 0.055),
            Paint()
              ..color = _rice.withValues(alpha: 0.75)
              ..strokeWidth = 0.012
              ..strokeCap = StrokeCap.round,
          );
          canvas.restore();
        }
        // Two vegetable rounds for contrast.
        _circleRing(canvas, const Offset(0.618, 0.478), 0.048, accent);
        _circleRing(canvas, const Offset(0.470, 0.492), 0.036, accent);
        break;
      case DishGlyph.pasta:
        _plate(canvas, rim: accent.withValues(alpha: 0.30));
        // Twirled pasta: nested arcs read as a nest of noodles.
        for (var i = 0; i < 4; i++) {
          final inset = 0.030 + i * 0.036;
          canvas.drawArc(
            Rect.fromCircle(
              center: const Offset(0.5, 0.520),
              radius: 0.170 - inset,
            ),
            -0.4 + i * 0.5,
            4.4,
            false,
            Paint()
              ..color = (i.isEven ? const Color(0xFFEBC98A) : accent)
                  .withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.030
              ..strokeCap = StrokeCap.round,
          );
        }
        // A fork laid across the plate.
        canvas.save();
        canvas.translate(0.5, 0.5);
        canvas.rotate(0.62);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.018, -0.235, 0.036, 0.30),
            const Radius.circular(0.018),
          ),
          Paint()..color = _rice,
        );
        for (final dx in const [-0.042, 0.0, 0.042]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx - 0.014, -0.300, 0.028, 0.090),
              const Radius.circular(0.014),
            ),
            Paint()..color = _rice,
          );
        }
        canvas.restore();
        break;
      case DishGlyph.salmonBowl:
        _bowl(canvas, fill: _rice, rim: _salmon.withValues(alpha: 0.34));
        // Two salmon fillets with white fat lines.
        for (final (cx, cy, rot) in const [
          (0.452, 0.418, -0.34),
          (0.575, 0.462, 0.22),
        ]) {
          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(rot);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-0.105, -0.048, 0.210, 0.096),
              const Radius.circular(0.030),
            ),
            Paint()..color = _salmon,
          );
          for (final dy in const [-0.018, 0.018]) {
            canvas.drawLine(
              Offset(-0.078, dy),
              Offset(0.078, dy - 0.010),
              Paint()
                ..color = _rice.withValues(alpha: 0.78)
                ..strokeWidth = 0.011
                ..strokeCap = StrokeCap.round,
            );
          }
          canvas.restore();
        }
        // Lemon wedge.
        final lemon = Path()
          ..moveTo(0.600, 0.352)
          ..arcTo(
            Rect.fromCircle(center: const Offset(0.600, 0.352), radius: 0.058),
            -0.6,
            2.4,
            false,
          )
          ..close();
        canvas.drawPath(lemon, Paint()..color = const Color(0xFFF6D86B));
        break;
      case DishGlyph.katsu:
        // A tray rather than a bowl: katsu is served on a plate.
        _plate(canvas, rim: accent.withValues(alpha: 0.30));
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.translate(0.452 + i * 0.012, 0.400 + i * 0.062);
          canvas.rotate(-0.10 + i * 0.05);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-0.125, -0.040, 0.250, 0.074),
              const Radius.circular(0.022),
            ),
            Paint()..color = accent,
          );
          // Panko speckles keep the cutlet from reading as a flat bar.
          for (final (dx, dy) in const [
            (-0.070, -0.014),
            (-0.010, 0.012),
            (0.062, -0.010),
          ]) {
            canvas.drawCircle(
              Offset(dx, dy),
              0.011,
              Paint()..color = _rice.withValues(alpha: 0.55),
            );
          }
          canvas.restore();
        }
        // Rice mound beside the cutlet.
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(0.652, 0.520),
            width: 0.120,
            height: 0.090,
          ),
          Paint()..color = _rice,
        );
        break;
      case DishGlyph.mushroomPasta:
        _plate(canvas, rim: accent.withValues(alpha: 0.30));
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: const Offset(0.5, 0.520),
              radius: 0.150 - i * 0.040,
            ),
            -0.3 + i * 0.9,
            4.6,
            false,
            Paint()
              ..color = const Color(0xFFE7D6B8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.028
              ..strokeCap = StrokeCap.round,
          );
        }
        // Mushroom caps with stems.
        for (final (cx, cy, scale) in const [
          (0.428, 0.432, 1.0),
          (0.548, 0.470, 1.12),
          (0.612, 0.396, 0.86),
        ]) {
          canvas.save();
          canvas.translate(cx, cy);
          canvas.scale(scale);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-0.016, 0.006, 0.032, 0.052),
              const Radius.circular(0.014),
            ),
            Paint()..color = const Color(0xFFF3E6CE),
          );
          canvas.drawPath(
            Path()
              ..moveTo(-0.062, 0.014)
              ..quadraticBezierTo(0, -0.086, 0.062, 0.014)
              ..quadraticBezierTo(0, 0.040, -0.062, 0.014)
              ..close(),
            Paint()..color = accent,
          );
          canvas.restore();
        }
        break;
    }

    canvas.restore();
  }

  /// A bowl seen slightly from above: body, rim, and an inner rice surface.
  void _bowl(Canvas canvas, {required Color fill, required Color rim}) {
    final body = Path()
      ..moveTo(0.240, 0.482)
      ..quadraticBezierTo(0.240, 0.742, 0.500, 0.752)
      ..quadraticBezierTo(0.760, 0.742, 0.760, 0.482)
      ..quadraticBezierTo(0.500, 0.560, 0.240, 0.482)
      ..close();
    canvas.drawPath(body, Paint()..color = rim.withValues(alpha: 0.55));
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rice.withValues(alpha: 0.0), _rice.withValues(alpha: 0.55)],
        ).createShader(const Rect.fromLTRB(0.24, 0.50, 0.76, 0.75)),
    );
    // Inner surface (the food) as an ellipse sitting in the rim.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.474),
        width: 0.520,
        height: 0.250,
      ),
      Paint()..color = fill,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.474),
        width: 0.520,
        height: 0.250,
      ),
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.022,
    );
  }

  /// A shallow plate with a visible rim, used for pasta and cutlet dishes.
  void _plate(Canvas canvas, {required Color rim}) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.520),
        width: 0.640,
        height: 0.400,
      ),
      Paint()..color = accent.withValues(alpha: 0.16),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.516),
        width: 0.560,
        height: 0.340,
      ),
      Paint()..color = _rice,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.516),
        width: 0.560,
        height: 0.340,
      ),
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018,
    );
  }

  void _pill(
    Canvas canvas,
    Offset centre,
    double width,
    double height,
    double rotation,
    Color color,
  ) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: width, height: height),
        Radius.circular(height / 2),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }

  void _circleRing(Canvas canvas, Offset centre, double radius, Color color) {
    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = _rice.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      centre,
      radius * 0.72,
      Paint()..color = color.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _DishPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.accent != accent;
}
