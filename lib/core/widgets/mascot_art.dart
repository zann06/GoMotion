import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/mascot_assets.dart';

/// Draws the GoMotion mascot: an original, code-drawn rider character.
///
/// The character is composed from flat brand shapes (no bundled art, no
/// network) so it renders crisply at any density and stays consistent on the
/// splash, home, service screens, empty/error states, and the map markers.
///
/// Art direction is fixed by the master reference: a friendly young rider with
/// dark navy hair, an electric-blue helmet carrying a white "G", a deep-blue
/// rider jacket with white accent stripes, and black riding gloves. Every pose
/// reuses the same head, face, and jacket so the character reads identically
/// everywhere.
class MascotArtPainter extends CustomPainter {
  const MascotArtPainter({required this.variant, this.wave = 0});

  /// Which pose to draw.
  final MascotVariant variant;

  /// Wave progress in `0..1`; only meaningful for [MascotVariant.wave].
  final double wave;

  // Illustration palette. Skin, hair, and paper tones are drawing detail, not
  // brand tokens, so they stay local to the character.
  static const Color _skin = Color(0xFFF3C9A9);
  static const Color _hair = Color(0xFF111A33);
  static const Color _mouth = Color(0xFF8C3B48);
  static const Color _blush = Color(0x30E8798A);
  static const Color _paper = Color(0xFFF8FAFF);
  static const Color _glass = Color(0xFFBFD8FF);
  static const Color _tyre = Color(0xFF16203A);

  bool get _isHappy =>
      variant == MascotVariant.hero ||
      variant == MascotVariant.wave ||
      variant == MascotVariant.success ||
      variant == MascotVariant.food ||
      variant == MascotVariant.send;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s);

    // Vehicle scenes sit behind the character.
    switch (variant) {
      case MascotVariant.ride:
        _motorbike(canvas);
        break;
      case MascotVariant.car:
        _car(canvas);
        break;
      case MascotVariant.hero:
      case MascotVariant.wave:
      case MascotVariant.loading:
      case MascotVariant.food:
      case MascotVariant.send:
      case MascotVariant.success:
      case MascotVariant.error:
        break;
    }

    // The car pose shows only the head and one arm above the bodywork, so the
    // character reads as sitting inside the car.
    if (variant != MascotVariant.car) {
      _torso(canvas);
      _arms(canvas);
    }
    _head(canvas);
    if (variant == MascotVariant.car) _drivingArm(canvas);
    _prop(canvas);

    canvas.restore();
  }

  // --- Scene: vehicles -----------------------------------------------------

  void _motorbike(Canvas canvas) {
    _wheel(canvas, const Offset(0.285, 0.82), 0.105);
    _wheel(canvas, const Offset(0.715, 0.82), 0.105);
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.30, 0.72, 0.70, 0.79),
      0.035,
      Paint()..color = AppColors.electricBlue,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.38, 0.65, 0.60, 0.74),
      0.03,
      Paint()..color = AppColors.deepBlue,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.655, 0.58, 0.775, 0.72),
      0.05,
      Paint()..color = AppColors.primaryIndigo,
    );
    canvas.drawLine(
      const Offset(0.66, 0.70),
      const Offset(0.76, 0.60),
      Paint()
        ..color = _tyre
        ..strokeWidth = 0.022
        ..strokeCap = StrokeCap.round,
    );
  }

  void _wheel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = _tyre);
    canvas.drawCircle(
      center,
      radius * 0.45,
      Paint()..color = AppColors.mapGround,
    );
  }

  void _car(Canvas canvas) {
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.30, 0.45, 0.70, 0.70),
      0.05,
      Paint()..color = AppColors.deepBlue,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.335, 0.49, 0.665, 0.665),
      0.04,
      Paint()..color = _glass,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.12, 0.64, 0.88, 0.90),
      0.06,
      Paint()..color = AppColors.primaryIndigo,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.15, 0.77, 0.85, 0.80),
      0.014,
      Paint()..color = AppColors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(const Offset(0.28, 0.90), 0.075, Paint()..color = _tyre);
    canvas.drawCircle(const Offset(0.72, 0.90), 0.075, Paint()..color = _tyre);
    canvas.drawCircle(
      const Offset(0.83, 0.72),
      0.028,
      Paint()..color = AppColors.white,
    );
  }

  // --- Body ----------------------------------------------------------------

  void _torso(Canvas canvas) {
    final bottom = variant == MascotVariant.ride ? 0.80 : 0.97;
    final jacket = Path()
      ..moveTo(0.33, bottom)
      ..lineTo(0.345, 0.60)
      ..quadraticBezierTo(0.5, 0.495, 0.655, 0.60)
      ..lineTo(0.67, bottom)
      ..close();
    canvas.drawPath(jacket, Paint()..color = AppColors.deepBlue);

    // Shoulder sheen keeps the flat jacket from looking pasted on.
    canvas.drawPath(
      jacket,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryIndigo.withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTRB(0.30, 0.50, 0.70, bottom)),
    );

    // Collar and zip.
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.415, 0.485, 0.585, 0.575),
      0.03,
      Paint()..color = AppColors.primaryIndigo,
    );
    _roundRect(
      canvas,
      Rect.fromLTRB(0.4945, 0.53, 0.5055, bottom - 0.02),
      0.006,
      Paint()..color = AppColors.white.withValues(alpha: 0.75),
    );
    // White accent stripe, straight from the reference jacket.
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.375, 0.635, 0.625, 0.672),
      0.016,
      Paint()..color = AppColors.white.withValues(alpha: 0.9),
    );
    _text(canvas, 'G', const Offset(0.545, 0.755), 0.085, AppColors.white);
  }

  void _arms(Canvas canvas) {
    final sleeve = Paint()
      ..color = AppColors.deepBlue
      ..strokeWidth = 0.075
      ..strokeCap = StrokeCap.round;
    final skin = Paint()..color = _skin;

    // The left arm is shared by every standing pose.
    final leftHand = switch (variant) {
      MascotVariant.success => const Offset(0.25, 0.44),
      MascotVariant.food || MascotVariant.send => const Offset(0.375, 0.79),
      MascotVariant.ride => const Offset(0.38, 0.70),
      _ => const Offset(0.30, 0.79),
    };
    canvas.drawLine(const Offset(0.345, 0.60), leftHand, sleeve);
    canvas.drawCircle(leftHand, 0.05, skin);

    switch (variant) {
      case MascotVariant.success:
        _armWithHand(
          canvas,
          sleeve,
          skin,
          const Offset(0.655, 0.60),
          const Offset(0.75, 0.44),
        );
        break;
      case MascotVariant.food:
      case MascotVariant.send:
        _armWithHand(
          canvas,
          sleeve,
          skin,
          const Offset(0.655, 0.60),
          const Offset(0.625, 0.79),
        );
        break;
      case MascotVariant.ride:
        _armWithHand(
          canvas,
          sleeve,
          skin,
          const Offset(0.655, 0.60),
          const Offset(0.66, 0.70),
        );
        break;
      case MascotVariant.error:
        _armWithHand(
          canvas,
          sleeve,
          skin,
          const Offset(0.655, 0.60),
          const Offset(0.645, 0.34),
        );
        break;
      case MascotVariant.loading:
        _armWithHand(
          canvas,
          sleeve,
          skin,
          const Offset(0.655, 0.60),
          const Offset(0.71, 0.79),
        );
        break;
      case MascotVariant.hero:
        _thumbsUp(canvas, sleeve, skin);
        break;
      case MascotVariant.wave:
        _wave(canvas, sleeve, skin);
        break;
      case MascotVariant.car:
        break;
    }
  }

  void _armWithHand(
    Canvas canvas,
    Paint sleeve,
    Paint skin,
    Offset shoulder,
    Offset hand,
  ) {
    canvas.drawLine(shoulder, hand, sleeve);
    canvas.drawCircle(hand, 0.05, skin);
  }

  void _thumbsUp(Canvas canvas, Paint sleeve, Paint skin) {
    const shoulder = Offset(0.655, 0.60);
    const fist = Offset(0.752, 0.495);
    canvas.drawLine(shoulder, fist, sleeve);
    canvas.drawCircle(fist, 0.058, skin);
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.733, 0.395, 0.771, 0.47),
      0.019,
      skin,
    );
  }

  void _wave(Canvas canvas, Paint sleeve, Paint skin) {
    // A single finite wave: the arm swings twice and settles back to rest.
    final swing = math.sin(wave * math.pi * 4) * 0.34 * (1 - wave * 0.55);
    canvas.save();
    canvas.translate(0.655, 0.60);
    canvas.rotate(swing);
    canvas.drawLine(Offset.zero, const Offset(0.06, -0.23), sleeve);
    const hand = Offset(0.075, -0.26);
    canvas.drawCircle(hand, 0.058, skin);
    canvas.drawCircle(hand.translate(-0.045, -0.045), 0.024, skin);
    canvas.drawCircle(hand.translate(0.005, -0.062), 0.024, skin);
    canvas.drawCircle(hand.translate(0.05, -0.038), 0.021, skin);
    canvas.restore();
  }

  void _drivingArm(Canvas canvas) {
    final sleeve = Paint()
      ..color = AppColors.deepBlue
      ..strokeWidth = 0.075
      ..strokeCap = StrokeCap.round;
    final skin = Paint()..color = _skin;
    canvas.drawLine(const Offset(0.60, 0.62), const Offset(0.85, 0.40), sleeve);
    const hand = Offset(0.865, 0.38);
    canvas.drawCircle(hand, 0.055, skin);
    canvas.drawCircle(hand.translate(0.03, -0.045), 0.021, skin);
    canvas.drawCircle(hand.translate(0.06, -0.008), 0.021, skin);
  }

  // --- Head ----------------------------------------------------------------

  void _head(Canvas canvas) {
    const center = Offset(0.5, 0.375);
    const radius = 0.175;
    final hairPaint = Paint()..color = _hair;

    // Hair sits behind the head and is clipped so it never rings the chin.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 1, 0.425));
    canvas.drawCircle(center.translate(0, -0.012), radius + 0.014, hairPaint);
    canvas.restore();

    canvas.drawCircle(center, radius, Paint()..color = _skin);

    // A single navy lock escapes on the side without the ear pad.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.337, 0.447),
        width: 0.062,
        height: 0.118,
      ),
      hairPaint,
    );

    // Helmet shell: a full dome that wraps the skull, wider than the head.
    final shell = Path()
      ..moveTo(0.268, 0.378)
      ..quadraticBezierTo(0.268, 0.158, 0.5, 0.158)
      ..quadraticBezierTo(0.732, 0.158, 0.732, 0.378)
      ..quadraticBezierTo(0.664, 0.412, 0.5, 0.412)
      ..quadraticBezierTo(0.336, 0.412, 0.268, 0.378)
      ..close();
    canvas.drawPath(shell, Paint()..color = AppColors.electricBlue);

    // Soft sheen across the shell so the flat fill reads as a glossy surface.
    canvas.save();
    canvas.clipPath(shell);
    canvas.drawRect(
      const Rect.fromLTRB(0.268, 0.158, 0.732, 0.412),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x22312A8F)],
          stops: [0.0, 0.42, 1.0],
        ).createShader(const Rect.fromLTRB(0.268, 0.158, 0.732, 0.412)),
    );
    canvas.restore();

    // Raised visor: the glass sits above the eyes so the face stays readable.
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.296, 0.268, 0.704, 0.366),
      0.042,
      Paint()..color = _glass,
    );
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.328, 0.29, 0.585, 0.314),
      0.012,
      Paint()..color = AppColors.white.withValues(alpha: 0.78),
    );

    // Brim under the visor.
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.248, 0.352, 0.752, 0.398),
      0.022,
      Paint()..color = AppColors.deepBlue,
    );

    // Ear pad with a deep-blue inset.
    canvas.drawCircle(
      const Offset(0.716, 0.374),
      0.058,
      Paint()..color = AppColors.primaryIndigo,
    );
    canvas.drawCircle(
      const Offset(0.716, 0.374),
      0.027,
      Paint()..color = AppColors.deepBlue,
    );

    // "G" decal on the shell, high on the dome.
    _text(canvas, 'G', const Offset(0.625, 0.238), 0.075, AppColors.white);

    // --- Face ---------------------------------------------------------------

    final eye = Paint()..color = _hair;
    final isPuzzled = variant == MascotVariant.error;
    for (final dx in const [-0.063, 0.063]) {
      _roundRect(
        canvas,
        Rect.fromCenter(
          center: Offset(0.5 + dx, 0.478),
          width: 0.054,
          height: isPuzzled ? 0.03 : 0.064,
        ),
        0.026,
        eye,
      );
      if (!isPuzzled) {
        canvas.drawCircle(
          Offset(0.5 + dx + 0.013, 0.467),
          0.011,
          Paint()..color = AppColors.white,
        );
        // A short brow keeps the expression friendly rather than blank.
        canvas.drawLine(
          Offset(0.5 + dx - 0.03, 0.437),
          Offset(0.5 + dx + 0.03, 0.433),
          Paint()
            ..color = _hair.withValues(alpha: 0.75)
            ..strokeWidth = 0.011
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (isPuzzled) {
      // A small frown reads as puzzled without being sad.
      canvas.drawPath(
        Path()
          ..moveTo(0.468, 0.552)
          ..quadraticBezierTo(0.5, 0.528, 0.532, 0.552),
        Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.016
          ..strokeCap = StrokeCap.round,
      );
    } else if (_isHappy) {
      canvas.drawPath(
        Path()
          ..moveTo(0.459, 0.522)
          ..quadraticBezierTo(0.5, 0.589, 0.541, 0.522)
          ..close(),
        Paint()..color = _mouth,
      );
      canvas.drawCircle(
        const Offset(0.397, 0.507),
        0.028,
        Paint()..color = _blush,
      );
      canvas.drawCircle(
        const Offset(0.603, 0.507),
        0.028,
        Paint()..color = _blush,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(0.469, 0.532)
          ..quadraticBezierTo(0.5, 0.559, 0.531, 0.532),
        Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.016
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // --- Props ---------------------------------------------------------------

  void _prop(Canvas canvas) {
    switch (variant) {
      case MascotVariant.food:
        // Paper bag with the brand mark, plus a drink.
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.375, 0.70, 0.605, 0.91),
          0.02,
          Paint()..color = _paper,
        );
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.375, 0.70, 0.605, 0.762),
          0.02,
          Paint()..color = AppColors.blueTint,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.445, 0.705)
            ..quadraticBezierTo(0.49, 0.665, 0.535, 0.705),
          Paint()
            ..color = AppColors.primaryIndigo
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.016,
        );
        _text(
          canvas,
          'G',
          const Offset(0.49, 0.833),
          0.075,
          AppColors.primaryIndigo,
        );
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.625, 0.735, 0.725, 0.89),
          0.016,
          Paint()..color = AppColors.primaryIndigo,
        );
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.618, 0.712, 0.732, 0.75),
          0.012,
          Paint()..color = AppColors.white,
        );
        break;
      case MascotVariant.send:
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.365, 0.68, 0.635, 0.91),
          0.02,
          Paint()..color = AppColors.primaryIndigo,
        );
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.485, 0.68, 0.515, 0.91),
          0.004,
          Paint()..color = AppColors.white,
        );
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.365, 0.752, 0.635, 0.784),
          0.004,
          Paint()..color = AppColors.white,
        );
        _text(canvas, 'G', const Offset(0.425, 0.848), 0.06, AppColors.white);
        break;
      case MascotVariant.success:
        canvas.drawCircle(
          const Offset(0.80, 0.225),
          0.12,
          Paint()..color = AppColors.white,
        );
        canvas.drawCircle(
          const Offset(0.80, 0.225),
          0.12,
          Paint()
            ..color = AppColors.primaryIndigo
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.018,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.745, 0.228)
            ..lineTo(0.786, 0.268)
            ..lineTo(0.862, 0.182),
          Paint()
            ..color = AppColors.success
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.03
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
        _sparkles(canvas, const [
          Offset(0.20, 0.20),
          Offset(0.14, 0.315),
          Offset(0.30, 0.13),
        ]);
        break;
      case MascotVariant.error:
        canvas.drawCircle(
          const Offset(0.785, 0.22),
          0.135,
          Paint()..color = AppColors.white,
        );
        canvas.drawCircle(
          const Offset(0.785, 0.22),
          0.135,
          Paint()
            ..color = AppColors.lightBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.014,
        );
        _text(
          canvas,
          '?',
          const Offset(0.785, 0.228),
          0.17,
          AppColors.deepBlue,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.30, 0.20)
            ..quadraticBezierTo(0.342, 0.268, 0.316, 0.30)
            ..quadraticBezierTo(0.274, 0.268, 0.30, 0.20),
          Paint()..color = AppColors.electricBlue,
        );
        break;
      case MascotVariant.hero:
        _sparkles(canvas, const [Offset(0.20, 0.22), Offset(0.28, 0.14)]);
        break;
      case MascotVariant.wave:
        _sparkles(canvas, const [Offset(0.83, 0.20), Offset(0.72, 0.12)]);
        break;
      case MascotVariant.loading:
      case MascotVariant.ride:
      case MascotVariant.car:
        break;
    }
  }

  void _sparkles(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.9)
      ..strokeWidth = 0.013
      ..strokeCap = StrokeCap.round;
    for (final p in points) {
      canvas.drawLine(p.translate(-0.03, 0), p.translate(0.03, 0), paint);
      canvas.drawLine(p.translate(0, -0.03), p.translate(0, 0.03), paint);
    }
  }

  // --- Helpers -------------------------------------------------------------

  void _roundRect(Canvas canvas, Rect rect, double radius, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant MascotArtPainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.wave != wave;
}
