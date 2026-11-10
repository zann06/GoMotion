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
///
/// The drawing aims for a *soft* read rather than a diagrammatic one:
/// - limbs are thick, tapered capsule strokes instead of hairlines;
/// - the torso is a bell with a curved hem, not a trapezoid;
/// - the head is slightly larger than life so the face carries the expression;
/// - every fill sits on a soft contact shadow, so the character never looks
///   pasted onto the badge.
class MascotArtPainter extends CustomPainter {
  const MascotArtPainter({required this.variant, this.wave = 0});

  /// Which pose to draw.
  final MascotVariant variant;

  /// Wave progress in `0..1`; only meaningful for [MascotVariant.wave].
  final double wave;

  // Illustration palette. Skin, hair, and paper tones are drawing detail, not
  // brand tokens, so they stay local to the character.
  static const Color _skin = Color(0xFFF6CDAA);
  static const Color _skinShade = Color(0xFFE7B48D);
  static const Color _hair = Color(0xFF141C36);
  static const Color _mouth = Color(0xFFB04A57);
  static const Color _tongue = Color(0xFFE0737F);
  static const Color _blush = Color(0x33F0708A);
  static const Color _paper = Color(0xFFF8FAFF);
  static const Color _glass = Color(0xFFCFE2FF);
  static const Color _glassEdge = Color(0xFF9EC2F7);
  static const Color _tyre = Color(0xFF16203A);
  static const Color _chrome = Color(0xFFB9CDEF);
  static const Color _white = Color(0xFFFFFFFF);

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
        _groundShadow(canvas, 0.5, 0.955, 0.20, 0.030);
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
    _groundShadow(canvas, 0.5, 0.925, 0.42, 0.045);

    // Rear wheel, then the front wheel slightly forward for a three-quarter
    // read instead of a flat profile.
    _wheel(canvas, const Offset(0.285, 0.845), 0.110);
    _wheel(canvas, const Offset(0.735, 0.845), 0.110);

    // Body: a tapered capsule from the seat to the fairing.
    final body = Path()
      ..moveTo(0.300, 0.790)
      ..quadraticBezierTo(0.500, 0.735, 0.700, 0.775)
      ..quadraticBezierTo(0.762, 0.790, 0.748, 0.822)
      ..quadraticBezierTo(0.500, 0.848, 0.300, 0.826)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.electricBlue);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55FFFFFF), Color(0x00000000)],
        ).createShader(const Rect.fromLTRB(0.28, 0.73, 0.76, 0.85)),
    );

    // Seat and fairing.
    _roundRect(
      canvas,
      const Rect.fromLTRB(0.405, 0.700, 0.610, 0.760),
      0.030,
      Paint()..color = AppColors.deepBlue,
    );
    final fairing = Path()
      ..moveTo(0.690, 0.640)
      ..quadraticBezierTo(0.790, 0.668, 0.782, 0.762)
      ..quadraticBezierTo(0.742, 0.782, 0.706, 0.762)
      ..quadraticBezierTo(0.688, 0.700, 0.690, 0.640)
      ..close();
    canvas.drawPath(fairing, Paint()..color = AppColors.primaryIndigo);
    canvas.drawPath(
      Path()
        ..moveTo(0.712, 0.675)
        ..quadraticBezierTo(0.756, 0.700, 0.752, 0.740),
      Paint()
        ..color = _white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..strokeCap = StrokeCap.round,
    );

    // Handlebars, curved rather than a single diagonal stick.
    canvas.drawPath(
      Path()
        ..moveTo(0.668, 0.700)
        ..quadraticBezierTo(0.740, 0.672, 0.806, 0.688),
      Paint()
        ..color = _tyre
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.024
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(0.808, 0.688),
      0.019,
      Paint()..color = AppColors.deepBlue,
    );
  }

  void _wheel(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = _tyre);
    canvas.drawCircle(
      center,
      radius * 0.58,
      Paint()..color = _chrome.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      center,
      radius * 0.34,
      Paint()..color = AppColors.mapGround,
    );
    canvas.drawCircle(center, radius * 0.10, Paint()..color = _tyre);
  }

  void _car(Canvas canvas) {
    _groundShadow(canvas, 0.5, 0.925, 0.40, 0.040);

    // Cabin: a rounded roof that flows into the bonnet line.
    final cabin = Path()
      ..moveTo(0.300, 0.560)
      ..quadraticBezierTo(0.360, 0.448, 0.500, 0.442)
      ..quadraticBezierTo(0.640, 0.448, 0.700, 0.560)
      ..quadraticBezierTo(0.500, 0.590, 0.300, 0.560)
      ..close();
    canvas.drawPath(cabin, Paint()..color = AppColors.deepBlue);

    // Windshield glass, inset with a soft top highlight.
    final glass = Path()
      ..moveTo(0.336, 0.552)
      ..quadraticBezierTo(0.385, 0.478, 0.500, 0.474)
      ..quadraticBezierTo(0.615, 0.478, 0.664, 0.552)
      ..quadraticBezierTo(0.500, 0.574, 0.336, 0.552)
      ..close();
    canvas.drawPath(glass, Paint()..color = _glass);
    canvas.drawPath(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x55FFFFFF), Color(0x00000000)],
        ).createShader(const Rect.fromLTRB(0.33, 0.47, 0.67, 0.58)),
    );

    // Bodywork with curved shoulders.
    final body = Path()
      ..moveTo(0.130, 0.760)
      ..quadraticBezierTo(0.140, 0.652, 0.300, 0.628)
      ..lineTo(0.700, 0.628)
      ..quadraticBezierTo(0.860, 0.652, 0.870, 0.760)
      ..quadraticBezierTo(0.870, 0.848, 0.800, 0.858)
      ..lineTo(0.200, 0.858)
      ..quadraticBezierTo(0.130, 0.848, 0.130, 0.760)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.primaryIndigo);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x4DFFFFFF), Color(0x00000000)],
          stops: [0.0, 0.55],
        ).createShader(const Rect.fromLTRB(0.13, 0.62, 0.87, 0.86)),
    );

    // Side accent line with a slight sweep.
    canvas.drawPath(
      Path()
        ..moveTo(0.175, 0.792)
        ..quadraticBezierTo(0.500, 0.772, 0.828, 0.792),
      Paint()
        ..color = _white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.016
        ..strokeCap = StrokeCap.round,
    );

    _wheel(canvas, const Offset(0.288, 0.862), 0.082);
    _wheel(canvas, const Offset(0.712, 0.862), 0.082);

    // Headlamp with a warm core.
    canvas.drawCircle(
      const Offset(0.836, 0.726),
      0.030,
      Paint()..color = _white,
    );
    canvas.drawCircle(
      const Offset(0.836, 0.726),
      0.014,
      Paint()..color = const Color(0xFFFFE9B0),
    );
  }

  // --- Body ----------------------------------------------------------------

  void _torso(Canvas canvas) {
    final bottom = variant == MascotVariant.ride ? 0.800 : 0.965;

    // The jacket is a bell: shoulders curve out, hem curves in, so the
    // silhouette reads soft instead of a straight-sided trapezoid.
    final jacket = Path()
      ..moveTo(0.336, bottom)
      ..quadraticBezierTo(0.320, 0.720, 0.352, 0.612)
      ..quadraticBezierTo(0.400, 0.545, 0.500, 0.530)
      ..quadraticBezierTo(0.600, 0.545, 0.648, 0.612)
      ..quadraticBezierTo(0.680, 0.720, 0.664, bottom)
      ..quadraticBezierTo(0.500, bottom + 0.030, 0.336, bottom)
      ..close();
    canvas.drawPath(jacket, Paint()..color = AppColors.deepBlue);

    // Shoulder sheen: light from the upper left, fading into the hem.
    canvas.save();
    canvas.clipPath(jacket);
    canvas.drawRect(
      Rect.fromLTRB(0.28, 0.50, 0.72, bottom + 0.04),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8C3B82F6), Color(0x00000000)],
          stops: [0.0, 0.62],
        ).createShader(Rect.fromLTRB(0.28, 0.50, 0.72, bottom + 0.04)),
    );
    // Hem shadow keeps the bell from reading flat.
    canvas.drawRect(
      Rect.fromLTRB(0.28, bottom - 0.10, 0.72, bottom + 0.04),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x33000000)],
        ).createShader(Rect.fromLTRB(0.28, bottom - 0.10, 0.72, bottom + 0.04)),
    );
    canvas.restore();

    // Collar: a soft V rather than a flat bar.
    final collar = Path()
      ..moveTo(0.412, 0.560)
      ..quadraticBezierTo(0.500, 0.600, 0.588, 0.560)
      ..quadraticBezierTo(0.560, 0.508, 0.500, 0.500)
      ..quadraticBezierTo(0.440, 0.508, 0.412, 0.560)
      ..close();
    canvas.drawPath(collar, Paint()..color = AppColors.primaryIndigo);

    // Zip, stopping short of the hem so it does not cut the silhouette.
    _stroke(
      canvas,
      Path()
        ..moveTo(0.500, 0.588)
        ..lineTo(0.500, bottom - 0.030),
      _white.withValues(alpha: 0.7),
      0.010,
    );

    // Chest stripe: slightly curved, hugging the body.
    _stroke(
      canvas,
      Path()
        ..moveTo(0.378, 0.688)
        ..quadraticBezierTo(0.500, 0.664, 0.622, 0.688),
      _white.withValues(alpha: 0.9),
      0.026,
    );

    // Shoulder flash on the character's right, echoing the helmet.
    _stroke(
      canvas,
      Path()
        ..moveTo(0.636, 0.612)
        ..quadraticBezierTo(0.664, 0.660, 0.660, 0.712),
      AppColors.electricBlue.withValues(alpha: 0.85),
      0.020,
    );

    _text(
      canvas,
      'G',
      Offset(0.556, bottom - 0.150),
      0.078,
      _white.withValues(alpha: 0.95),
    );
  }

  void _arms(Canvas canvas) {
    final sleeve = Paint()
      ..color = AppColors.deepBlue
      ..strokeWidth = 0.088
      ..strokeCap = StrokeCap.round;
    final cuff = Paint()
      ..color = AppColors.primaryIndigo
      ..strokeWidth = 0.088
      ..strokeCap = StrokeCap.round;

    // The left arm is shared by every standing pose, drawn with a slight elbow
    // bend so it is never a straight stick.
    final leftHand = switch (variant) {
      MascotVariant.success => const Offset(0.262, 0.452),
      MascotVariant.food || MascotVariant.send => const Offset(0.382, 0.782),
      MascotVariant.ride => const Offset(0.386, 0.712),
      _ => const Offset(0.306, 0.780),
    };
    final leftElbow = Offset(
      (0.352 + leftHand.dx) / 2 - 0.014,
      (0.632 + leftHand.dy) / 2,
    );
    _limb(canvas, const Offset(0.352, 0.632), leftElbow, sleeve);
    _limb(canvas, leftElbow, leftHand, sleeve);
    _cuff(canvas, leftElbow, leftHand, cuff);
    _hand(canvas, leftHand, 0.048);

    switch (variant) {
      case MascotVariant.success:
        _raisedArm(
          canvas,
          sleeve,
          cuff,
          const Offset(0.648, 0.632),
          const Offset(0.756, 0.452),
          cheer: true,
        );
        break;
      case MascotVariant.food:
      case MascotVariant.send:
        _raisedArm(
          canvas,
          sleeve,
          cuff,
          const Offset(0.648, 0.632),
          const Offset(0.628, 0.780),
        );
        break;
      case MascotVariant.ride:
        _raisedArm(
          canvas,
          sleeve,
          cuff,
          const Offset(0.640, 0.628),
          const Offset(0.652, 0.716),
        );
        break;
      case MascotVariant.error:
        _raisedArm(
          canvas,
          sleeve,
          cuff,
          const Offset(0.648, 0.632),
          const Offset(0.652, 0.352),
        );
        break;
      case MascotVariant.loading:
        _raisedArm(
          canvas,
          sleeve,
          cuff,
          const Offset(0.648, 0.632),
          const Offset(0.716, 0.792),
        );
        break;
      case MascotVariant.hero:
        _thumbsUp(canvas, sleeve, cuff);
        break;
      case MascotVariant.wave:
        _wave(canvas, sleeve, cuff);
        break;
      case MascotVariant.car:
        break;
    }
  }

  void _raisedArm(
    Canvas canvas,
    Paint sleeve,
    Paint cuff,
    Offset shoulder,
    Offset hand, {
    bool cheer = false,
  }) {
    final elbow = Offset(
      (shoulder.dx + hand.dx) / 2 + 0.026,
      (shoulder.dy + hand.dy) / 2 + (cheer ? 0.036 : 0.010),
    );
    _limb(canvas, shoulder, elbow, sleeve);
    _limb(canvas, elbow, hand, sleeve);
    _cuff(canvas, elbow, hand, cuff);
    _hand(canvas, hand, 0.048);
  }

  void _thumbsUp(Canvas canvas, Paint sleeve, Paint cuff) {
    const shoulder = Offset(0.648, 0.632);
    const fist = Offset(0.760, 0.500);
    const elbow = Offset(0.726, 0.578);
    _limb(canvas, shoulder, elbow, sleeve);
    _limb(canvas, elbow, fist, sleeve);
    _cuff(canvas, elbow, fist, cuff);

    // Fist plus an uplifted thumb, drawn as one soft silhouette.
    _hand(canvas, fist, 0.056);
    final thumb = RRect.fromRectAndRadius(
      const Rect.fromLTRB(0.744, 0.396, 0.784, 0.470),
      const Radius.circular(0.020),
    );
    canvas.drawRRect(thumb, Paint()..color = _skin);
    canvas.drawCircle(
      const Offset(0.764, 0.404),
      0.020,
      Paint()..color = _skin,
    );
    canvas.drawRRect(
      thumb,
      Paint()
        ..color = _skinShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.006,
    );
  }

  void _wave(Canvas canvas, Paint sleeve, Paint cuff) {
    // A single finite wave: the arm swings twice and settles into a relaxed
    // raise, so the last frame still reads as a greeting.
    final swing = math.sin(wave * math.pi * 3.4) * 0.40 * (1 - wave * 0.45);
    canvas.save();
    canvas.translate(0.648, 0.632);
    canvas.rotate(swing);

    const elbow = Offset(0.086, -0.108);
    const hand = Offset(0.126, -0.256);
    _limb(canvas, Offset.zero, elbow, sleeve);
    _limb(canvas, elbow, hand, sleeve);
    _cuff(canvas, elbow, hand, cuff);

    // Open palm with four soft fingers, splayed like a real wave.
    canvas.drawCircle(hand, 0.050, Paint()..color = _skin);
    final finger = Paint()
      ..color = _skin
      ..strokeWidth = 0.026
      ..strokeCap = StrokeCap.round;
    for (final (dx, dy, ex, ey) in const [
      (-0.036, -0.030, -0.062, -0.070),
      (-0.008, -0.042, -0.014, -0.090),
      (0.022, -0.038, 0.040, -0.080),
      (0.044, -0.018, 0.074, -0.048),
    ]) {
      canvas.drawLine(hand.translate(dx, dy), hand.translate(ex, ey), finger);
    }
    canvas.restore();
  }

  void _drivingArm(Canvas canvas) {
    final sleeve = Paint()
      ..color = AppColors.deepBlue
      ..strokeWidth = 0.082
      ..strokeCap = StrokeCap.round;
    final cuff = Paint()
      ..color = AppColors.primaryIndigo
      ..strokeWidth = 0.082
      ..strokeCap = StrokeCap.round;
    const shoulder = Offset(0.592, 0.640);
    const elbow = Offset(0.742, 0.528);
    const hand = Offset(0.842, 0.470);
    _limb(canvas, shoulder, elbow, sleeve);
    _limb(canvas, elbow, hand, sleeve);
    _cuff(canvas, elbow, hand, cuff);

    _hand(canvas, hand, 0.050);
    final finger = Paint()
      ..color = _skin
      ..strokeWidth = 0.022
      ..strokeCap = StrokeCap.round;
    for (final dy in const [-0.026, 0.0, 0.026]) {
      canvas.drawLine(
        hand.translate(0.024, dy),
        hand.translate(0.060, dy - 0.006),
        finger,
      );
    }
  }

  /// A tapered limb segment: a capsule with a slightly narrower wrist end.
  void _limb(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    // A soft rounding cap at the outer end hides the seam between segments.
    canvas.drawCircle(to, paint.strokeWidth / 2, Paint()..color = paint.color);
  }

  /// A brand cuff band a short distance before the hand.
  void _cuff(Canvas canvas, Offset from, Offset to, Paint paint) {
    final delta = to - from;
    final length = delta.distance;
    if (length <= 0.001) return;
    final unit = delta / length;
    final start = to - unit * math.min(0.062, length * 0.62);
    final end = to - unit * math.min(0.020, length * 0.18);
    canvas.drawLine(start, end, paint);
  }

  void _hand(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = _skin);
    // A soft inner shade so the hand has volume at small sizes.
    canvas.drawCircle(
      center.translate(radius * 0.18, radius * 0.22),
      radius * 0.72,
      Paint()..color = _skinShade.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.06, -radius * 0.06),
      radius * 0.62,
      Paint()..color = _skin,
    );
  }

  // --- Head ----------------------------------------------------------------

  void _head(Canvas canvas) {
    const center = Offset(0.5, 0.372);
    const radius = 0.188;
    final hairPaint = Paint()..color = _hair;

    // Contact shadow under the chin ties the head to the torso.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.545),
        width: 0.190,
        height: 0.060,
      ),
      Paint()..color = AppColors.deepBlue.withValues(alpha: 0.35),
    );

    // Hair sits behind the head and is clipped so it never rings the chin.
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 1, 0.430));
    canvas.drawCircle(center.translate(0, -0.010), radius + 0.016, hairPaint);
    canvas.restore();

    // Face with a jaw that narrows slightly toward the chin.
    final face = Path()
      ..moveTo(0.312, 0.372)
      ..quadraticBezierTo(0.312, 0.180, 0.500, 0.180)
      ..quadraticBezierTo(0.688, 0.180, 0.688, 0.372)
      ..quadraticBezierTo(0.688, 0.500, 0.500, 0.560)
      ..quadraticBezierTo(0.312, 0.500, 0.312, 0.372)
      ..close();
    canvas.drawPath(face, Paint()..color = _skin);
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x00FFFFFF), Color(0x26B4764D)],
          stops: [0.55, 1.0],
        ).createShader(const Rect.fromLTRB(0.31, 0.18, 0.69, 0.56)),
    );

    // A single navy lock escapes on the side without the ear pad.
    canvas.drawPath(
      Path()
        ..moveTo(0.348, 0.404)
        ..quadraticBezierTo(0.316, 0.462, 0.334, 0.512)
        ..quadraticBezierTo(0.362, 0.470, 0.366, 0.410)
        ..close(),
      hairPaint,
    );

    // Helmet shell: a full dome that wraps the skull, wider than the head.
    final shell = Path()
      ..moveTo(0.246, 0.368)
      ..quadraticBezierTo(0.240, 0.128, 0.500, 0.122)
      ..quadraticBezierTo(0.760, 0.128, 0.754, 0.368)
      ..quadraticBezierTo(0.660, 0.412, 0.500, 0.414)
      ..quadraticBezierTo(0.340, 0.412, 0.246, 0.368)
      ..close();
    canvas.drawPath(shell, Paint()..color = AppColors.electricBlue);

    // Soft sheen across the shell so the flat fill reads as a glossy surface.
    canvas.save();
    canvas.clipPath(shell);
    canvas.drawRect(
      const Rect.fromLTRB(0.24, 0.12, 0.76, 0.42),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x80FFFFFF), Color(0x00FFFFFF), Color(0x2E1B1F6E)],
          stops: [0.0, 0.44, 1.0],
        ).createShader(const Rect.fromLTRB(0.24, 0.12, 0.76, 0.42)),
    );
    // A soft specular sweep on the crown sells the curvature.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.418, 0.218),
        width: 0.230,
        height: 0.070,
      ),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x00FFFFFF), Color(0x8CFFFFFF), Color(0x00FFFFFF)],
            ).createShader(
              Rect.fromCenter(
                center: const Offset(0.418, 0.218),
                width: 0.230,
                height: 0.070,
              ),
            ),
    );
    canvas.restore();

    // Raised visor: the glass sits above the eyes so the face stays readable.
    final visor = Path()
      ..moveTo(0.286, 0.262)
      ..quadraticBezierTo(0.500, 0.220, 0.714, 0.262)
      ..quadraticBezierTo(0.716, 0.318, 0.700, 0.352)
      ..quadraticBezierTo(0.500, 0.318, 0.300, 0.352)
      ..quadraticBezierTo(0.284, 0.318, 0.286, 0.262)
      ..close();
    canvas.drawPath(visor, Paint()..color = _glass);
    canvas.drawPath(
      visor,
      Paint()
        ..color = _glassEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008,
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(0.330, 0.286)
        ..quadraticBezierTo(0.470, 0.258, 0.616, 0.280),
      _white.withValues(alpha: 0.8),
      0.014,
    );

    // Brim under the visor: a curved lip rather than a straight bar.
    final brim = Path()
      ..moveTo(0.236, 0.352)
      ..quadraticBezierTo(0.500, 0.398, 0.764, 0.352)
      ..quadraticBezierTo(0.760, 0.398, 0.700, 0.412)
      ..quadraticBezierTo(0.500, 0.446, 0.300, 0.412)
      ..quadraticBezierTo(0.240, 0.398, 0.236, 0.352)
      ..close();
    canvas.drawPath(brim, Paint()..color = AppColors.deepBlue);

    // Ear pad with a deep-blue inset.
    canvas.drawCircle(
      const Offset(0.722, 0.376),
      0.060,
      Paint()..color = AppColors.primaryIndigo,
    );
    canvas.drawCircle(
      const Offset(0.722, 0.376),
      0.028,
      Paint()..color = AppColors.deepBlue,
    );

    // "G" decal on the shell, high on the dome.
    _text(canvas, 'G', const Offset(0.616, 0.196), 0.078, _white);

    // --- Face ---------------------------------------------------------------

    final isPuzzled = variant == MascotVariant.error;
    for (final dx in const [-0.064, 0.064]) {
      final eyeCenter = Offset(0.5 + dx, 0.430);
      // Soft eye socket shading first, so the eyes sit in the face.
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: 0.086, height: 0.086),
        Paint()..color = _skinShade.withValues(alpha: 0.28),
      );

      if (isPuzzled) {
        // Squinting arcs read as puzzled, not blank.
        _stroke(
          canvas,
          Path()
            ..moveTo(eyeCenter.dx - 0.024, eyeCenter.dy)
            ..quadraticBezierTo(
              eyeCenter.dx,
              eyeCenter.dy - 0.018,
              eyeCenter.dx + 0.024,
              eyeCenter.dy,
            ),
          _hair,
          0.014,
        );
        continue;
      }

      // Iris + pupil + two highlights: the layered read keeps the eye alive at
      // small sizes, where a single dot would look like a speck.
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: 0.056, height: 0.066),
        Paint()..color = _hair,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: eyeCenter.translate(0, 0.012),
          width: 0.040,
          height: 0.042,
        ),
        Paint()..color = const Color(0xFF2C3A63),
      );
      canvas.drawCircle(
        eyeCenter.translate(0.011, -0.014),
        0.014,
        Paint()..color = _white,
      );
      canvas.drawCircle(
        eyeCenter.translate(-0.013, 0.017),
        0.007,
        Paint()..color = _white.withValues(alpha: 0.65),
      );

      // A short, lifted brow keeps the expression friendly.
      _stroke(
        canvas,
        Path()
          ..moveTo(0.5 + dx - 0.030, 0.382)
          ..quadraticBezierTo(0.5 + dx, 0.368, 0.5 + dx + 0.030, 0.378),
        _hair.withValues(alpha: 0.8),
        0.012,
      );
    }

    // Nose: a tiny soft shadow, never a hard line.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.492),
        width: 0.028,
        height: 0.018,
      ),
      Paint()..color = _skinShade.withValues(alpha: 0.55),
    );

    if (isPuzzled) {
      // A small frown reads as puzzled without being sad.
      _stroke(
        canvas,
        Path()
          ..moveTo(0.466, 0.544)
          ..quadraticBezierTo(0.5, 0.518, 0.534, 0.544),
        _mouth,
        0.016,
      );
    } else if (_isHappy) {
      // Open smile: a filled shape with a tongue and a soft lower lip.
      final smile = Path()
        ..moveTo(0.452, 0.516)
        ..quadraticBezierTo(0.500, 0.598, 0.548, 0.516)
        ..quadraticBezierTo(0.500, 0.560, 0.452, 0.516)
        ..close();
      canvas.drawPath(smile, Paint()..color = _mouth);
      canvas.save();
      canvas.clipPath(smile);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0.5, 0.566),
          width: 0.052,
          height: 0.036,
        ),
        Paint()..color = _tongue,
      );
      canvas.restore();

      canvas.drawCircle(
        const Offset(0.386, 0.492),
        0.030,
        Paint()..color = _blush,
      );
      canvas.drawCircle(
        const Offset(0.614, 0.492),
        0.030,
        Paint()..color = _blush,
      );
    } else {
      _stroke(
        canvas,
        Path()
          ..moveTo(0.468, 0.528)
          ..quadraticBezierTo(0.500, 0.556, 0.532, 0.528),
        _mouth,
        0.016,
      );
    }
  }

  // --- Props ---------------------------------------------------------------

  void _prop(Canvas canvas) {
    switch (variant) {
      case MascotVariant.food:
        // Paper bag with the brand mark, plus a drink.
        _groundShadow(canvas, 0.500, 0.918, 0.150, 0.022);
        final bag = Path()
          ..moveTo(0.380, 0.712)
          ..lineTo(0.608, 0.712)
          ..quadraticBezierTo(0.620, 0.905, 0.600, 0.912)
          ..quadraticBezierTo(0.500, 0.928, 0.390, 0.912)
          ..quadraticBezierTo(0.370, 0.905, 0.380, 0.712)
          ..close();
        canvas.drawPath(bag, Paint()..color = _paper);
        canvas.save();
        canvas.clipPath(bag);
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.370, 0.700, 0.620, 0.772),
          0.018,
          Paint()..color = AppColors.blueTint,
        );
        canvas.restore();
        _stroke(
          canvas,
          Path()
            ..moveTo(0.446, 0.712)
            ..quadraticBezierTo(0.494, 0.668, 0.542, 0.712),
          AppColors.primaryIndigo,
          0.016,
        );
        _text(
          canvas,
          'G',
          const Offset(0.494, 0.842),
          0.072,
          AppColors.primaryIndigo,
        );

        // Drink cup with a lid and straw.
        final cup = Path()
          ..moveTo(0.636, 0.742)
          ..lineTo(0.726, 0.742)
          ..quadraticBezierTo(0.716, 0.892, 0.702, 0.898)
          ..quadraticBezierTo(0.660, 0.904, 0.660, 0.898)
          ..quadraticBezierTo(0.646, 0.892, 0.636, 0.742)
          ..close();
        canvas.drawPath(cup, Paint()..color = AppColors.primaryIndigo);
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.628, 0.716, 0.734, 0.752),
          0.014,
          Paint()..color = _white,
        );
        _stroke(
          canvas,
          Path()
            ..moveTo(0.694, 0.718)
            ..lineTo(0.714, 0.664),
          AppColors.electricBlue,
          0.014,
        );
        break;
      case MascotVariant.send:
        _groundShadow(canvas, 0.500, 0.918, 0.170, 0.022);
        final box = Path()
          ..moveTo(0.366, 0.700)
          ..lineTo(0.634, 0.700)
          ..lineTo(0.620, 0.906)
          ..quadraticBezierTo(0.500, 0.922, 0.380, 0.906)
          ..close();
        canvas.drawPath(box, Paint()..color = AppColors.primaryIndigo);
        canvas.drawPath(
          box,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x40FFFFFF), Color(0x00000000)],
              stops: [0.0, 0.7],
            ).createShader(const Rect.fromLTRB(0.36, 0.70, 0.64, 0.91)),
        );
        _stroke(
          canvas,
          Path()
            ..moveTo(0.500, 0.706)
            ..lineTo(0.500, 0.912),
          _white,
          0.024,
        );
        _stroke(
          canvas,
          Path()
            ..moveTo(0.372, 0.782)
            ..quadraticBezierTo(0.500, 0.792, 0.628, 0.782),
          _white,
          0.020,
        );
        // A small shipping label on the parcel face.
        _roundRect(
          canvas,
          const Rect.fromLTRB(0.404, 0.820, 0.472, 0.876),
          0.010,
          Paint()..color = _white.withValues(alpha: 0.92),
        );
        _text(
          canvas,
          'G',
          const Offset(0.438, 0.848),
          0.040,
          AppColors.primaryIndigo,
        );
        break;
      case MascotVariant.success:
        // Celebration ring with a soft outer glow.
        canvas.drawCircle(
          const Offset(0.806, 0.208),
          0.136,
          Paint()
            ..color = AppColors.primaryIndigo.withValues(alpha: 0.20)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.03),
        );
        canvas.drawCircle(
          const Offset(0.806, 0.208),
          0.116,
          Paint()..color = _white,
        );
        canvas.drawCircle(
          const Offset(0.806, 0.208),
          0.116,
          Paint()
            ..color = AppColors.primaryIndigo
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.017,
        );
        _stroke(
          canvas,
          Path()
            ..moveTo(0.752, 0.210)
            ..lineTo(0.792, 0.252)
            ..lineTo(0.866, 0.166),
          AppColors.success,
          0.030,
        );
        _sparkles(canvas, const [
          Offset(0.196, 0.196),
          Offset(0.140, 0.318),
          Offset(0.302, 0.126),
        ]);
        break;
      case MascotVariant.error:
        canvas.drawCircle(
          const Offset(0.792, 0.204),
          0.132,
          Paint()
            ..color = AppColors.deepBlue.withValues(alpha: 0.14)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.028),
        );
        canvas.drawCircle(
          const Offset(0.792, 0.204),
          0.112,
          Paint()..color = _white,
        );
        canvas.drawCircle(
          const Offset(0.792, 0.204),
          0.112,
          Paint()
            ..color = AppColors.lightBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.013,
        );
        _text(
          canvas,
          '?',
          const Offset(0.792, 0.208),
          0.150,
          AppColors.deepBlue,
        );
        // A small "sweat" drop, drawn as a droplet rather than a leaf.
        final drop = Path()
          ..moveTo(0.300, 0.176)
          ..quadraticBezierTo(0.348, 0.250, 0.322, 0.282)
          ..quadraticBezierTo(0.278, 0.286, 0.268, 0.244)
          ..quadraticBezierTo(0.266, 0.212, 0.300, 0.176)
          ..close();
        canvas.drawPath(drop, Paint()..color = AppColors.electricBlue);
        break;
      case MascotVariant.hero:
        _sparkles(canvas, const [Offset(0.196, 0.226), Offset(0.284, 0.140)]);
        break;
      case MascotVariant.wave:
        _sparkles(canvas, const [Offset(0.840, 0.188), Offset(0.736, 0.116)]);
        break;
      case MascotVariant.loading:
      case MascotVariant.ride:
      case MascotVariant.car:
        break;
    }
  }

  void _sparkles(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = _white.withValues(alpha: 0.92)
      ..strokeWidth = 0.013
      ..strokeCap = StrokeCap.round;
    for (final p in points) {
      // Four-point star drawn as two crossed strokes with tapered ends.
      canvas.drawLine(p.translate(-0.030, 0), p.translate(0.030, 0), paint);
      canvas.drawLine(p.translate(0, -0.030), p.translate(0, 0.030), paint);
      canvas.drawCircle(
        p,
        0.008,
        Paint()..color = _white.withValues(alpha: 0.92),
      );
    }
  }

  // --- Helpers -------------------------------------------------------------

  /// A wide, soft ellipse used as a contact shadow so the character is grounded.
  void _groundShadow(
    Canvas canvas,
    double cx,
    double cy,
    double halfWidth,
    double height,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: halfWidth * 2,
        height: height * 2,
      ),
      Paint()
        ..color = AppColors.deepBlue.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.018),
    );
  }

  void _stroke(Canvas canvas, Path path, Color color, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

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
          letterSpacing: -0.01,
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
