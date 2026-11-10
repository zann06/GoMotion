import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/reduced_motion_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_mark_painter.dart';
import 'app_motion.dart';

/// The GoMotion brand mark: the heavy, forward-leaning **G** from the identity.
///
/// The mark is drawn rather than bundled so it stays crisp at every size — a
/// 20px lock-up in a list and the 132px splash signature share one geometry
/// ([GoMotionMarkPainter]). It is a single traced outline, so the stroke weight
/// is baked in and the glyph never distorts when scaled.
///
/// The same painter stamps the G on the mascot's helmet and chest, which is what
/// keeps the character and the logo reading as one brand.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    this.size = 40,
    this.foreground = AppColors.white,
    this.background,
    this.gradient,
    this.padding = 0.16,
    this.semanticLabel,
    super.key,
  });

  /// Edge length of the square the mark is drawn into.
  final double size;

  /// Stroke colour of the trail and chevron.
  final Color foreground;

  /// Flat fill behind the mark. Ignored when [gradient] is set.
  final Color? background;

  /// Gradient fill behind the mark, e.g. the brand gradient.
  final Gradient? gradient;

  /// Fraction of [size] kept clear around the drawing.
  final double padding;

  /// Accessible description; when null the mark is decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fill = gradient;
    final painter = CustomPaint(
      painter: _LogoMarkPainter(foreground: foreground, padding: padding),
      size: Size.square(size),
    );

    final content = fill == null && background == null
        ? painter
        : DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill == null ? background : null,
              gradient: fill,
            ),
            child: Padding(padding: EdgeInsets.all(size * 0.1), child: painter),
          );

    final sized = SizedBox(width: size, height: size, child: content);
    if (semanticLabel == null) return ExcludeSemantics(child: sized);
    return Semantics(label: semanticLabel, image: true, child: sized);
  }
}

class _LogoMarkPainter extends CustomPainter {
  const _LogoMarkPainter({required this.foreground, required this.padding});

  final Color foreground;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (s <= 0) return;
    // The traced glyph already fills its box edge to edge, so the clear space is
    // applied by insetting the paint box rather than by re-deriving geometry.
    final inset = s * padding;
    GoMotionMarkPainter.paint(
      canvas,
      Rect.fromLTWH(
        (size.width - s) / 2 + inset,
        (size.height - s) / 2 + inset,
        s - inset * 2,
        s - inset * 2,
      ),
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoMarkPainter oldDelegate) =>
      oldDelegate.foreground != foreground || oldDelegate.padding != padding;
}

/// Horizontal brand lock-up: the mark beside the wordmark.
///
/// Used where the brand introduces itself (splash, welcome, about). The mark
/// settles in with one finite [AppReveal] so the lock-up never animates forever.
class AppBrandLockup extends ConsumerWidget {
  const AppBrandLockup({
    this.markSize = 40,
    this.title = 'GoMotion',
    this.showTagline = false,
    this.foreground = AppColors.deepNavy,
    this.markForeground = AppColors.white,
    this.gradient = AppColors.heroWash,
    this.textStyle,
    super.key,
  });
  final double markSize;
  final String title;
  final bool showTagline;
  final Color foreground;
  final Color markForeground;

  /// Fill behind the mark. Null renders the mark as bare strokes, which is what
  /// a brand lock-up on an already-gradient surface wants.
  final Gradient? gradient;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogoMark(
          size: markSize,
          foreground: markForeground,
          gradient: gradient,
          semanticLabel: 'GoMotion logo',
        ),
        SizedBox(width: markSize * LogoShape.lockupGap),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    textStyle ??
                    TextStyle(
                      fontSize: markSize * 0.62,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                      color: foreground,
                    ),
              ),
              if (showTagline)
                Text(
                  'Move smarter',
                  style: TextStyle(
                    fontSize: math.max(11, markSize * 0.26),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: foreground.withValues(alpha: 0.62),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The splash brand signature: mark, wordmark, and tagline in one measured
/// block with a soft halo behind the mark.
///
/// This is the first brand impression, so it gets one deliberate entrance
/// rather than a hard cut: the mark fades and lifts in over [AppDuration.enter].
class AppSplashSignature extends ConsumerWidget {
  const AppSplashSignature({this.size = 132, super.key});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(reduceMotionProvider).enabled;
    final mark = Stack(
      alignment: Alignment.center,
      children: [
        // Halo: a wide, very soft ring that lifts the white mark off the
        // gradient without a hard badge edge.
        Container(
          width: size * 1.34,
          height: size * 1.34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.white.withValues(alpha: 0.20),
                AppColors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.55, 1.0],
            ),
          ),
        ),
        AppLogoMark(
          size: size,
          foreground: AppColors.white,
          background: AppColors.white.withValues(alpha: 0.10),
          semanticLabel: 'GoMotion logo',
        ),
      ],
    );

    if (reduced) return mark;

    return AppReveal(offset: 0.10, child: mark);
  }
}

/// A compact logo chip for dense rows (settings, about) where the mark sits
/// beside a label. Uses the brand gradient so it reads as the same object as
/// the splash mark, not a separate icon.
class AppLogoChip extends StatelessWidget {
  const AppLogoChip({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryIndigo.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: AppLogoMark(
          size: size * 0.66,
          foreground: AppColors.white,
          padding: 0.02,
          semanticLabel: 'GoMotion logo',
        ),
      ),
    );
  }
}

/// Keeps the shared logo tokens discoverable next to the widgets that use them.
///
/// The mark is geometry-only, so it needs no asset and no network; these are the
/// only tunables the brand surface exposes.
abstract final class LogoShape {
  /// Weight of the ring's stroke as a fraction of the mark box, measured on the
  /// identity reference. The value is documentation: the glyph bakes its weight
  /// into the traced outline, so nothing scales it at paint time.
  static const double strokeWeight = 0.30;

  /// Clear space kept around the drawing, as a fraction of the mark box.
  static const double clearance = 0.10;

  /// Gap between the mark and a wordmark, as a multiple of the mark size.
  static const double lockupGap = 0.34;

  /// Default chip radius, as a fraction of the chip size.
  static const double chipRadius = 0.32;
}

/// Convenience: the mark tinted for use on a light surface.
AppLogoMark lightLogoMark({double size = 40, Key? key}) => AppLogoMark(
  key: key,
  size: size,
  foreground: AppColors.white,
  gradient: AppColors.primaryGradient,
);

/// Convenience: the mark tinted for use on a deep brand surface.
AppLogoMark onBrandLogoMark({double size = 40, Key? key}) => AppLogoMark(
  key: key,
  size: size,
  foreground: AppColors.white,
  padding: LogoShape.clearance,
);

/// Extra vertical rhythm used by the splash signature.
const double kBrandSignatureSpacing = AppSpacing.xl;
