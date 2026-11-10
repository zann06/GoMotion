import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/reduced_motion_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../feedback/app_haptics.dart';

/// Shared motion primitives for the polish pass.
///
/// Everything here follows the same two rules:
///
/// 1. Animations are *finite* one-shots. A decorative effect never keeps a
///    ticker alive, so screens stay at 60 FPS and `pumpAndSettle` can always
///    reach a stable frame.
/// 2. Reduced motion is honoured structurally. When motion is reduced the
///    widget returns its child unchanged instead of parking it on an invisible
///    first frame, because a hidden first frame would also hide real content.
///
/// See `docs/ANIMATION_SPECIFICATION.md` for the duration tokens these use.

/// Fades and lifts a child into place as it appears.
///
/// Use the [index] to stagger a list of sibling cards, which reads as one
/// deliberate movement instead of several independent ones.
class AppReveal extends ConsumerStatefulWidget {
  const AppReveal({
    required this.child,
    this.index = 0,
    this.offset = 0.05,
    this.delay,
    super.key,
  });

  /// The content to reveal.
  final Widget child;

  /// Position in a staggered sequence; each step adds a small delay.
  final int index;

  /// Fraction of the child's height it rises from while fading in.
  final double offset;

  /// Overrides the computed stagger, e.g. for a single hero element.
  final Duration? delay;

  /// Delay added per [index]. Kept short so a long list never feels slow.
  static const Duration _stagger = Duration(milliseconds: 45);

  /// Beyond this many steps the delay stops growing, so the tail of a long
  /// list is never left waiting.
  static const int _maxSteps = 7;

  @override
  ConsumerState<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends ConsumerState<AppReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;
  Animation<Offset>? _offset;

  @override
  void initState() {
    super.initState();

    // Under reduced motion nothing is created at all: no ticker, no pending
    // work, and the child renders on its settled frame with the first pump.
    if (ref.read(reduceMotionProvider).enabled) return;

    final steps = widget.index.clamp(0, AppReveal._maxSteps);
    final delay = widget.delay ?? AppReveal._stagger * steps;
    const enter = AppDuration.enter;
    final total = delay + enter;
    // The stagger is part of one timeline rather than a pending timer, so the
    // ticker starts on the first frame and the whole sequence always settles.
    final start = total.inMicroseconds == 0
        ? 0.0
        : delay.inMicroseconds / total.inMicroseconds;

    final controller = AnimationController(vsync: this, duration: total);
    _controller = controller;
    _opacity = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    _offset = Tween<Offset>(begin: Offset(0, widget.offset), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, 1, curve: Curves.easeOutCubic),
          ),
        );
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _opacity;
    final offset = _offset;
    if (opacity == null || offset == null) return widget.child;

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}

/// A restrained press response for surfaces that have no ink ripple.
///
/// The theme disables splashes, so tappable cards scale down briefly instead.
/// Reduced motion only removes the scaling; the tap callback always fires, so a
/// control is never dead for users who turn animation off.
class AppPressFeedback extends ConsumerStatefulWidget {
  const AppPressFeedback({
    required this.child,
    required this.onTap,
    this.scale = 0.985,
    this.haptics = true,
    this.liftOnHover = true,
    super.key,
  });

  final Widget child;

  /// Invoked on a completed tap.
  final VoidCallback onTap;

  /// How far the surface shrinks while held.
  final double scale;

  /// Whether to fire a light haptic tick on tap.
  final bool haptics;

  /// Whether a pointer hover gently lifts the surface, matching the press-in
  /// gesture on web and desktop.
  final bool liftOnHover;

  @override
  ConsumerState<AppPressFeedback> createState() => _AppPressFeedbackState();
}

class _AppPressFeedbackState extends ConsumerState<AppPressFeedback> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final motion = ref.watch(reduceMotionProvider);
    final scale = _pressed
        ? widget.scale
        : (_hovered && widget.liftOnHover ? 1.008 : 1.0);

    return GestureDetector(
      // Opaque so the empty padding of a card is tappable too, matching the
      // full-surface target the card draws.
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        if (widget.haptics) AppHaptics.select();
        widget.onTap();
      },
      onTapCancel: () => _setPressed(false),
      child: MouseRegion(
        // Signals interactivity on web and desktop, where there is no ripple.
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AnimatedScale(
          scale: scale,
          duration: motion.resolve(AppDuration.press),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A linear progress track that eases between values.
///
/// Simulated progress arrives in discrete steps; a plain indicator would jump.
/// The bar is decoration only — callers keep the same value available as text,
/// so progress is never conveyed by colour and width alone.
class AppProgressBar extends ConsumerWidget {
  const AppProgressBar({
    required this.value,
    this.height = 8,
    this.gradient,
    this.color,
    this.trackColor,
    this.semanticLabel,
    super.key,
  });

  /// Target progress, clamped to 0–1.
  final double value;

  final double height;

  /// Fill painter. Defaults to the brand gradient, or a flat [color].
  final Gradient? gradient;
  final Color? color;
  final Color? trackColor;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    final target = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2);

    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()} percent',
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: radius,
          child: TweenAnimationBuilder<double>(
            // `begin: 0` gives the bar a short fill-in the first time it is
            // shown; later updates tween from wherever the bar currently is.
            tween: Tween<double>(begin: 0, end: target),
            duration: motion.resolve(AppDuration.value),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: trackColor ?? AppColors.skeleton),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: animated,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        gradient:
                            gradient ??
                            (color == null ? AppColors.primaryGradient : null),
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Counts a numeric value to its new value instead of swapping the text.
///
/// Used for values that change in steps, such as a percentage or a demo fare.
/// The final value is exposed to assistive technology, never an intermediate
/// animation frame.
class AppAnimatedCounter extends ConsumerWidget {
  const AppAnimatedCounter({
    required this.value,
    required this.format,
    this.style,
    super.key,
  });

  /// The value to count to.
  final num value;

  /// Renders an intermediate or final value as display text.
  final String Function(num value) format;

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: motion.resolve(AppDuration.value),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) =>
          Text(format(animated), style: style, semanticsLabel: format(value)),
    );
  }
}
