import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/reduced_motion_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/mascot_assets.dart';
import 'mascot_art.dart';

/// The GoMotion mascot, reused across the app so the brand reads as one
/// character everywhere.
///
/// The mascot renders on a soft brand-gradient badge by default. Motion is a
/// short, finite one-shot choreography that plays once on mount and then holds
/// still: this keeps the mascot feeling alive without running a perpetual
/// ticker, and it fully respects reduced motion by rendering the final pose
/// immediately.
///
/// When bundled pose art is enabled ([MascotAssets.bundled]) the widget prefers
/// the bitmap and falls back to the drawn character, so call sites never change.
class Mascot extends ConsumerStatefulWidget {
  const Mascot({
    required this.variant,
    this.animation,
    this.size = MascotSize.medium,
    this.badge = true,
    this.art,
    this.semanticLabel,
    super.key,
  });

  /// Which pose to show.
  final MascotVariant variant;

  /// Motion intent. Defaults to the pose's natural motion.
  final MascotAnimation? animation;

  /// Rendered size.
  final MascotSize size;

  /// Whether to draw the circular brand-gradient badge behind the character.
  final bool badge;

  /// Optional bitmap override, e.g. a bundled PNG pose.
  final Widget? art;

  /// Overrides the accessible description.
  final String? semanticLabel;

  @override
  ConsumerState<Mascot> createState() => _MascotState();
}

class _MascotState extends ConsumerState<Mascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  MascotAnimation get _animation =>
      widget.animation ?? widget.variant.defaultAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(_animation),
    );
    // Reduced motion, or a static pose, shows the settled frame immediately.
    // The value is never left at zero, so the mascot can never render invisible.
    if (ref.read(reduceMotionProvider).enabled ||
        _animation == MascotAnimation.none) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static Duration _durationFor(MascotAnimation animation) =>
      switch (animation) {
        MascotAnimation.none => Duration.zero,
        MascotAnimation.idle => const Duration(milliseconds: 620),
        MascotAnimation.wave => const Duration(milliseconds: 1500),
        MascotAnimation.happy => const Duration(milliseconds: 900),
        MascotAnimation.riding => const Duration(milliseconds: 760),
        MascotAnimation.driving => const Duration(milliseconds: 760),
        MascotAnimation.deliver => const Duration(milliseconds: 820),
      };

  @override
  Widget build(BuildContext context) {
    final px = widget.size.px;
    final art = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _pose(_controller.value, px),
    );

    return Semantics(
      label: widget.semanticLabel ?? widget.variant.semanticLabel,
      image: true,
      child: SizedBox(
        width: px,
        height: px,
        child: widget.badge ? _badge(px, art) : art,
      ),
    );
  }

  Widget _badge(double px, Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.heroWash,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: SizedBox(width: px * 0.88, height: px * 0.88, child: child),
          ),
        ),
      ),
    );
  }

  /// Applies the one-shot choreography for the current animation frame.
  Widget _pose(double t, double px) {
    final enter = Curves.easeOutCubic.transform((t / 0.72).clamp(0.0, 1.0));
    var dy = 0.0;
    var scale = 1.0;
    var wave = 0.0;

    switch (_animation) {
      case MascotAnimation.none:
        break;
      case MascotAnimation.idle:
        dy = (1 - enter) * 0.10;
        scale = 0.94 + 0.06 * enter;
        break;
      case MascotAnimation.wave:
        dy = (1 - enter) * 0.10;
        scale = 0.94 + 0.06 * enter;
        wave = t <= 0.32 ? 0 : ((t - 0.32) / 0.68).clamp(0.0, 1.0);
        break;
      case MascotAnimation.happy:
        dy = (1 - enter) * 0.06;
        scale = 0.82 + 0.18 * Curves.elasticOut.transform(t.clamp(0.0, 1.0));
        break;
      case MascotAnimation.riding:
        dy = (1 - enter) * 0.12;
        scale = 0.92 + 0.08 * enter;
        break;
      case MascotAnimation.driving:
        dy = (1 - enter) * 0.08;
        scale = 0.92 + 0.08 * enter;
        break;
      case MascotAnimation.deliver:
        dy = (1 - enter) * 0.10;
        scale = 0.93 + 0.07 * enter;
        break;
    }

    return Opacity(
      opacity: 0.15 + 0.85 * enter,
      child: Transform.translate(
        offset: Offset(0, dy * px),
        child: Transform.scale(scale: scale, child: _art(wave)),
      ),
    );
  }

  Widget _art(double wave) {
    final override = widget.art;
    if (override != null) return override;

    final path = MascotAssets.fileFor(widget.variant);
    if (path != null) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _drawn(wave),
      );
    }
    return _drawn(wave);
  }

  Widget _drawn(double wave) => RepaintBoundary(
    child: CustomPaint(
      painter: MascotArtPainter(variant: widget.variant, wave: wave),
    ),
  );
}

/// A small service banner: the mascot in a pose that matches the service beside
/// a short, honest line of copy.
///
/// Used at the top of the GoFood and GoSend forms and on the GoRide matching
/// screen so each service carries its own character pose without crowding the
/// content above the fold.
class MascotBanner extends StatelessWidget {
  const MascotBanner({
    required this.variant,
    required this.title,
    required this.message,
    this.animation,
    super.key,
  });

  /// The pose to show.
  final MascotVariant variant;

  /// Motion intent; defaults to the pose's natural motion.
  final MascotAnimation? animation;

  /// Short headline beside the mascot.
  final String title;

  /// One line of supporting, clearly-fictional copy.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.indigoTint,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          Mascot(
            variant: variant,
            animation: animation,
            size: MascotSize.small,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.itemTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(message, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact "the mascot is getting ready" indicator for loading states.
/// Three brand dots ease in sequence. It is purely decorative, so it holds
/// still when motion is reduced.
class MascotLoadingDots extends ConsumerWidget {
  const MascotLoadingDots({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          _Dot(delay: i * 0.18, animate: motion.allowLoops),
        ],
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay, required this.animate});

  final double delay;
  final bool animate;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    // A finite pulse, not a perpetual loop: it animates only while the widget
    // exists and stops on its own, so it never holds up a frame-settle.
    if (widget.animate) _controller.forward(from: widget.delay);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final pulse = t == 0 || t == 1
            ? 0.0
            : Curves.easeInOut.transform(t < 0.5 ? t * 2 : (1 - t) * 2);
        return Opacity(
          opacity: 0.35 + 0.65 * pulse,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
