import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/mascot_assets.dart';
import 'app_mark_painter.dart';

/// Draws the GoMotion mascot: an original, code-drawn rider character.
///
/// The character is composed from flat brand shapes (no bundled art, no
/// network) so it renders crisply at any density and stays consistent on the
/// splash, home, service screens, empty/error states, and the map markers.
///
/// Art direction follows the identity reference: a friendly young rider in an
/// anime-illustration style — dark navy hair spilling out of a glossy blue
/// helmet with a violet visor and a white **G** decal, a deep-blue rider jacket
/// with the G mark and "GoMotion" on the chest, a black riding glove, and a
/// confident thumbs-up. Every pose reuses the same head, face, helmet, and
/// jacket so the character reads identically everywhere.
///
/// The drawing aims for a *soft, illustrated* read rather than a diagrammatic
/// one:
/// - limbs are thick tapered capsules, not hairlines;
/// - the torso is a bell with a curved hem, so the silhouette is human;
/// - the head is slightly larger than life so the face carries the expression;
/// - hair is a layered, spiky mass with a lighter rim light;
/// - every fill sits on a soft contact shadow, so the character is grounded.
class MascotArtPainter extends CustomPainter {
  const MascotArtPainter({required this.variant, this.wave = 0});

  /// Which pose to draw.
  final MascotVariant variant;

  /// Wave progress in `0..1`; only meaningful for [MascotVariant.wave].
  final double wave;

  // --- Illustration palette -------------------------------------------------
  // Skin, hair, and cloth tones are drawing detail, not brand tokens, so they
  // stay local to the character.
  static const Color _skin = Color(0xFFF7D3B2);
  static const Color _skinShade = Color(0xFFE9B58F);
  static const Color _hair = Color(0xFF1B2340);
  static const Color _hairLight = Color(0xFF3A4470);
  static const Color _mouth = Color(0xFFA83F4C);
  static const Color _tongue = Color(0xFFDE6F79);
  static const Color _blush = Color(0x33F0708A);
  static const Color _paper = Color(0xFFF8FAFF);
  static const Color _white = Color(0xFFFFFFFF);

  // Helmet: bright, saturated blue with a cool violet visor, matching the
  // reference's glossy shell.
  static const Color _helmetBlue = Color(0xFF1D4ED8);
  static const Color _helmetLight = Color(0xFF3B7BF6);
  static const Color _helmetDark = Color(0xFF10247A);
  static const Color _visor = Color(0xFF2A2B6B);
  static const Color _visorSheen = Color(0xFF8E8FE0);

  // Jacket: deep royal blue with an electric sky-blue flash.
  static const Color _jacket = Color(0xFF16307F);
  static const Color _jacketFlash = Color(0xFF4E8DF7);

  // Riding glove and strap hardware.
  static const Color _glove = Color(0xFF141A2E);
  static const Color _gloveLight = Color(0xFF2C3450);
  static const Color _chrome = Color(0xFFB9CDEF);
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
    canvas.drawPath(body, Paint()..color = _helmetLight);
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
    canvas.drawPath(fairing, Paint()..color = _helmetBlue);
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
    canvas.drawPath(glass, Paint()..color = _visorSheen.withValues(alpha: 0.5));
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
    canvas.drawPath(body, Paint()..color = _helmetBlue);
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
    canvas.drawPath(jacket, Paint()..color = _jacket);

    // Shoulder sheen: light from the upper left, fading into the hem.
    canvas.save();
    canvas.clipPath(jacket);
    canvas.drawRect(
      Rect.fromLTRB(0.28, 0.50, 0.72, bottom + 0.04),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8C2F63E8), Color(0x00000000)],
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
    canvas.drawPath(collar, Paint()..color = _helmetBlue);

    // Zip, stopping short of the hem so it does not cut the silhouette.
    _stroke(
      canvas,
      Path()
        ..moveTo(0.500, 0.588)
        ..lineTo(0.500, bottom - 0.030),
      _white.withValues(alpha: 0.7),
      0.010,
    );

    // Chest flash: the sky-blue wedge from the reference, angled across the
    // shoulder rather than a symmetric stripe.
    final flash = Path()
      ..moveTo(0.396, 0.700)
      ..lineTo(0.566, 0.648)
      ..lineTo(0.610, 0.700)
      ..lineTo(0.430, 0.744)
      ..close();
    canvas.drawPath(
      flash,
      Paint()..color = _jacketFlash.withValues(alpha: 0.9),
    );

    // Shoulder flash on the character's right, echoing the helmet.
    _stroke(
      canvas,
      Path()
        ..moveTo(0.636, 0.612)
        ..quadraticBezierTo(0.664, 0.660, 0.660, 0.712),
      _helmetLight.withValues(alpha: 0.85),
      0.020,
    );

    // Chest branding: the same G mark as the logo with the wordmark under it,
    // raised clear of the curved hem so neither is clipped at small sizes.
    const markSize = 0.128;
    final markTop = bottom - 0.290;
    GoMotionMarkPainter.paint(
      canvas,
      Rect.fromLTWH(
        0.500 - markSize / 2,
        markTop,
        markSize,
        markSize *
            GoMotionMarkPainter.referenceBox.height /
            GoMotionMarkPainter.referenceBox.width,
      ),
      _white,
    );
    _text(
      canvas,
      'GoMotion',
      Offset(0.500, markTop + 0.168),
      0.058,
      _white.withValues(alpha: 0.96),
      weight: FontWeight.w700,
    );
  }

  void _arms(Canvas canvas) {
    final sleeve = Paint()
      ..color = _jacket
      ..strokeWidth = 0.088
      ..strokeCap = StrokeCap.round;
    final cuff = Paint()
      ..color = _helmetBlue
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

  /// The signature pose: a gloved fist with the thumb lifted, exactly as in the
  /// reference. The forearm swings out beside the torso so the gesture reads on
  /// its own silhouette instead of hiding behind the head.
  void _thumbsUp(Canvas canvas, Paint sleeve, Paint cuff) {
    const shoulder = Offset(0.652, 0.628);
    const fist = Offset(0.790, 0.556);
    const elbow = Offset(0.812, 0.716);
    _limb(canvas, shoulder, elbow, sleeve);
    _limb(canvas, elbow, fist, sleeve);
    _cuff(canvas, elbow, fist, cuff);

    // The thumb is drawn first, so the glove overlaps its base and the joint
    // looks like a thumb emerging from a fist.
    final thumbBase = fist.translate(-0.006, -0.028);
    final thumbTip = fist.translate(-0.024, -0.124);
    canvas.drawLine(
      thumbBase,
      thumbTip,
      Paint()
        ..color = _skin
        ..strokeWidth = 0.058
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(thumbTip, 0.032, Paint()..color = _skin);
    // A soft shade down the inner side gives the thumb a rounded form.
    canvas.drawCircle(
      thumbTip.translate(0.016, 0.004),
      0.017,
      Paint()..color = _skinShade.withValues(alpha: 0.45),
    );

    _glovedFist(canvas, fist, 0.070);
  }

  /// A black riding glove: palm block, knuckle highlight, finger creases, and a
  /// blue brand band across the cuff.
  void _glovedFist(Canvas canvas, Offset center, double radius) {
    final block = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: radius * 1.9,
        height: radius * 1.8,
      ),
      Radius.circular(radius * 0.62),
    );
    canvas.drawRRect(block, Paint()..color = _glove);
    // A soft upper highlight reads as knuckle leather.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(-radius * 0.16, -radius * 0.30),
          width: radius * 1.40,
          height: radius * 0.62,
        ),
        Radius.circular(radius * 0.34),
      ),
      Paint()..color = _gloveLight.withValues(alpha: 0.85),
    );
    // Creases between the folded fingers.
    for (final dy in const [-0.18, 0.14]) {
      _stroke(
        canvas,
        Path()
          ..moveTo(center.dx - radius * 0.62, center.dy + radius * dy)
          ..lineTo(center.dx + radius * 0.60, center.dy + radius * dy),
        _gloveLight.withValues(alpha: 0.75),
        radius * 0.10,
      );
    }
    // Brand band across the cuff, echoing the reference's blue trim.
    _stroke(
      canvas,
      Path()
        ..moveTo(center.dx - radius * 0.80, center.dy + radius * 0.66)
        ..lineTo(center.dx + radius * 0.72, center.dy + radius * 0.60),
      _helmetLight.withValues(alpha: 0.9),
      radius * 0.16,
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

    // Open gloved palm with four soft fingers, splayed like a real wave.
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
    // Glove cuff at the wrist keeps the hand consistent with the fist pose.
    canvas.drawCircle(hand.translate(0, 0.030), 0.034, Paint()..color = _glove);
    canvas.restore();
  }

  void _drivingArm(Canvas canvas) {
    final sleeve = Paint()
      ..color = _jacket
      ..strokeWidth = 0.082
      ..strokeCap = StrokeCap.round;
    final cuff = Paint()
      ..color = _helmetBlue
      ..strokeWidth = 0.082
      ..strokeCap = StrokeCap.round;
    const shoulder = Offset(0.592, 0.640);
    const elbow = Offset(0.742, 0.528);
    const hand = Offset(0.842, 0.470);
    _limb(canvas, shoulder, elbow, sleeve);
    _limb(canvas, elbow, hand, sleeve);
    _cuff(canvas, elbow, hand, cuff);

    _glovedFist(canvas, hand, 0.058);
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
    // Contact shadow under the chin ties the head to the torso.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0.5, 0.545),
        width: 0.190,
        height: 0.060,
      ),
      Paint()..color = AppColors.deepBlue.withValues(alpha: 0.35),
    );

    // Hair sits behind the head: a layered, spiky mass with a lighter rim so it
    // does not read as a flat blob at small sizes.
    _hairBack(canvas);

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

    // Ears, peeking under the helmet at both sides.
    for (final dx in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0.500 + 0.172 * dx, 0.404),
          width: 0.052,
          height: 0.076,
        ),
        Paint()..color = _skin,
      );
    }

    // The fringe goes on before the helmet so the shell overlaps its top edge.
    _hairFront(canvas);
    _helmet(canvas);

    // --- Face ---------------------------------------------------------------

    final isPuzzled = variant == MascotVariant.error;
    // Anime eye styling: closed happy arcs for cheerful poses, a big iris for
    // the rest, and a squint for the puzzled pose.
    final happyEyes = _isHappy;
    for (final dx in const [-0.066, 0.066]) {
      final eyeCenter = Offset(0.5 + dx, 0.430);
      // Soft eye socket shading first, so the eyes sit in the face.
      canvas.drawOval(
        Rect.fromCenter(center: eyeCenter, width: 0.086, height: 0.086),
        Paint()..color = _skinShade.withValues(alpha: 0.26),
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

      if (happyEyes) {
        // A closed, upward-curving eye: the single strongest "anime smile"
        // signal, and it stays legible as a dark tick at 20px.
        _stroke(
          canvas,
          Path()
            ..moveTo(eyeCenter.dx - 0.030, eyeCenter.dy + 0.008)
            ..quadraticBezierTo(
              eyeCenter.dx,
              eyeCenter.dy - 0.026,
              eyeCenter.dx + 0.030,
              eyeCenter.dy + 0.008,
            ),
          _hair,
          0.017,
        );
        continue;
      }

      // Open eye: iris + pupil + two highlights, layered so it reads alive even
      // where a single dot would look like a speck.
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
    }

    // Brows: thicker and angled up at the outer end, which is what makes the
    // face read confident rather than neutral.
    if (!happyEyes) {
      for (final dx in const [-0.066, 0.066]) {
        _stroke(
          canvas,
          Path()
            ..moveTo(0.5 + dx - 0.030, 0.382)
            ..quadraticBezierTo(0.5 + dx, 0.366, 0.5 + dx + 0.030, 0.378),
          _hair.withValues(alpha: 0.85),
          0.013,
        );
      }
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

    // A single hair lock escapes beside the left cheek, in front of everything,
    // so the hairline reads as hair rather than a painted band. The fringe
    // itself is drawn under the helmet (see [_hairFront]).
    _sideLock(canvas);
  }

  /// The hair mass behind the head: a soft, layered silhouette with a few
  /// swept tips rather than a spiky crown, so it reads as hair at any size.
  void _hairBack(Canvas canvas) {
    final hair = Path()
      // Crown, drawn wider than the skull so the hair frames the face.
      ..moveTo(0.300, 0.372)
      ..quadraticBezierTo(0.286, 0.200, 0.400, 0.150)
      // Swept tips, each a gentle wedge instead of a needle.
      ..quadraticBezierTo(0.430, 0.112, 0.474, 0.148)
      ..quadraticBezierTo(0.492, 0.104, 0.540, 0.140)
      ..quadraticBezierTo(0.576, 0.108, 0.612, 0.152)
      ..quadraticBezierTo(0.660, 0.140, 0.676, 0.180)
      ..quadraticBezierTo(0.722, 0.216, 0.700, 0.380)
      ..quadraticBezierTo(0.700, 0.436, 0.660, 0.456)
      ..quadraticBezierTo(0.612, 0.404, 0.610, 0.352)
      ..lineTo(0.390, 0.352)
      ..quadraticBezierTo(0.386, 0.404, 0.340, 0.456)
      ..quadraticBezierTo(0.300, 0.436, 0.300, 0.372)
      ..close();
    canvas.drawPath(hair, Paint()..color = _hair);

    // Rim light along the top-left, so the mass has direction.
    canvas.save();
    canvas.clipPath(hair);
    canvas.drawRect(
      const Rect.fromLTRB(0.28, 0.06, 0.72, 0.26),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hairLight.withValues(alpha: 0.55), const Color(0x00000000)],
          stops: const [0.0, 0.75],
        ).createShader(const Rect.fromLTRB(0.28, 0.06, 0.72, 0.26)),
    );
    canvas.restore();
  }

  /// The forehead fringe, drawn *before* the helmet: the brim overlaps its top
  /// edge, so the bangs read as hair peeking out from under the helmet.
  ///
  /// One soft sweep instead of separate pointed locks: individual points read as
  /// fangs at the 44px inline size, which is the smallest the mascot gets.
  void _hairFront(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(0.316, 0.318)
        ..quadraticBezierTo(0.348, 0.372, 0.410, 0.366)
        ..quadraticBezierTo(0.452, 0.386, 0.500, 0.370)
        ..quadraticBezierTo(0.556, 0.382, 0.592, 0.354)
        ..quadraticBezierTo(0.622, 0.372, 0.656, 0.350)
        ..quadraticBezierTo(0.640, 0.278, 0.598, 0.258)
        ..quadraticBezierTo(0.500, 0.240, 0.394, 0.256)
        ..quadraticBezierTo(0.340, 0.268, 0.316, 0.318)
        ..close(),
      Paint()..color = _hair,
    );
  }

  /// The lock that falls beside the left cheek, drawn last so it sits in front
  /// of the jaw.
  void _sideLock(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(0.348, 0.404)
        ..quadraticBezierTo(0.316, 0.462, 0.334, 0.512)
        ..quadraticBezierTo(0.362, 0.470, 0.366, 0.410)
        ..close(),
      Paint()..color = _hair,
    );
  }

  /// The helmet: glossy blue dome, violet visor on the brow, a white G decal on
  /// the crown, and a deep-blue ear pad.
  ///
  /// The brim stops above the eyebrows so the fringe peeks out underneath; that
  /// strip of hair is what separates the helmet from the face at small sizes.
  void _helmet(Canvas canvas) {
    // Shell: a dome that wraps the skull, wider than the head.
    final shell = Path()
      ..moveTo(0.250, 0.306)
      ..quadraticBezierTo(0.240, 0.120, 0.500, 0.122)
      ..quadraticBezierTo(0.760, 0.120, 0.750, 0.306)
      ..quadraticBezierTo(0.660, 0.348, 0.500, 0.350)
      ..quadraticBezierTo(0.340, 0.348, 0.250, 0.306)
      ..close();
    canvas.drawPath(shell, Paint()..color = _helmetBlue);

    canvas.save();
    canvas.clipPath(shell);
    // Base shading: the crown catches light, the sides fall into deep blue.
    canvas.drawRect(
      const Rect.fromLTRB(0.24, 0.12, 0.76, 0.42),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8C5C93FF), Color(0x0010207A), Color(0x6610207A)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(const Rect.fromLTRB(0.24, 0.12, 0.76, 0.42)),
    );
    // A broad specular sweep on the crown sells the gloss.
    canvas.drawPath(
      Path()
        ..moveTo(0.300, 0.250)
        ..quadraticBezierTo(0.360, 0.190, 0.470, 0.180)
        ..quadraticBezierTo(0.400, 0.232, 0.336, 0.292)
        ..close(),
      Paint()..color = _white.withValues(alpha: 0.30),
    );
    // A hard-edged glint, like the highlight band in the reference.
    canvas.drawPath(
      Path()
        ..moveTo(0.520, 0.166)
        ..lineTo(0.606, 0.150)
        ..lineTo(0.560, 0.230)
        ..lineTo(0.492, 0.238)
        ..close(),
      Paint()..color = _white.withValues(alpha: 0.55),
    );
    canvas.restore();

    // Visor: violet glass, flipped up onto the brow. It deliberately stops above
    // the brows so the whole face stays readable — a visor over the eyes makes
    // the character look blind at small sizes.
    final visor = Path()
      ..moveTo(0.300, 0.196)
      ..quadraticBezierTo(0.500, 0.166, 0.700, 0.196)
      ..quadraticBezierTo(0.702, 0.230, 0.690, 0.248)
      ..quadraticBezierTo(0.500, 0.224, 0.310, 0.248)
      ..quadraticBezierTo(0.298, 0.230, 0.300, 0.196)
      ..close();
    canvas.drawPath(visor, Paint()..color = _visor.withValues(alpha: 0.88));
    // Glass sheen sweeping across the visor.
    canvas.drawPath(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x8CB9BCFF), Color(0x22101040)],
          stops: [0.1, 0.8],
        ).createShader(const Rect.fromLTRB(0.28, 0.16, 0.72, 0.25)),
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(0.338, 0.214)
        ..quadraticBezierTo(0.470, 0.194, 0.612, 0.212),
      _white.withValues(alpha: 0.75),
      0.011,
    );

    // Brim under the visor: a curved lip rather than a straight bar. It stops
    // above the brows so the fringe shows between the helmet and the face.
    final brim = Path()
      ..moveTo(0.244, 0.290)
      ..quadraticBezierTo(0.500, 0.336, 0.756, 0.290)
      ..quadraticBezierTo(0.752, 0.336, 0.694, 0.350)
      ..quadraticBezierTo(0.500, 0.384, 0.306, 0.350)
      ..quadraticBezierTo(0.248, 0.336, 0.244, 0.290)
      ..close();
    canvas.drawPath(brim, Paint()..color = _helmetDark);

    // Ear pad with a deep-blue inset and a chrome fixing.
    canvas.drawCircle(
      const Offset(0.722, 0.328),
      0.058,
      Paint()..color = _helmetBlue,
    );
    canvas.drawCircle(
      const Offset(0.722, 0.328),
      0.042,
      Paint()..color = _helmetDark,
    );
    canvas.drawCircle(
      const Offset(0.722, 0.328),
      0.014,
      Paint()..color = _chrome.withValues(alpha: 0.55),
    );

    // "G" decal on the shell: the same mark as the app logo.
    const decal = Rect.fromLTWH(0.578, 0.176, 0.096, 0.096);
    GoMotionMarkPainter.paint(canvas, decal, _white);
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
          _helmetBlue,
          0.016,
        );
        GoMotionMarkPainter.paint(
          canvas,
          const Rect.fromLTWH(0.458, 0.806, 0.072, 0.072),
          _helmetBlue,
        );

        // Drink cup with a lid and straw.
        final cup = Path()
          ..moveTo(0.636, 0.742)
          ..lineTo(0.726, 0.742)
          ..quadraticBezierTo(0.716, 0.892, 0.702, 0.898)
          ..quadraticBezierTo(0.660, 0.904, 0.660, 0.898)
          ..quadraticBezierTo(0.646, 0.892, 0.636, 0.742)
          ..close();
        canvas.drawPath(cup, Paint()..color = _helmetBlue);
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
          _helmetLight,
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
        canvas.drawPath(box, Paint()..color = _helmetBlue);
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
        GoMotionMarkPainter.paint(
          canvas,
          const Rect.fromLTWH(0.416, 0.828, 0.040, 0.040),
          _helmetBlue,
        );
        break;
      case MascotVariant.success:
        // Celebration ring with a soft outer glow.
        canvas.drawCircle(
          const Offset(0.806, 0.208),
          0.136,
          Paint()
            ..color = _helmetBlue.withValues(alpha: 0.20)
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
            ..color = _helmetBlue
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
        canvas.drawPath(drop, Paint()..color = _helmetLight);
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
    Color color, {
    FontWeight weight = FontWeight.w800,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
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
