import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/mascot_assets.dart';
import 'mascot_art.dart';

/// The mascot vehicle marker used on the schematic map.
///
/// This is the GoMotion vehicle "character": the mascot riding or driving,
/// inside a brand-gradient disc with a white ring. It stays upright — the
/// character is never distorted — while a small compass tick on the ring
/// rotates to show the current travel bearing. When the vehicle is moving, two
/// faint puffs trail behind it so motion reads at a glance.
///
/// The marker is deliberately cheap: flat vector shapes and a single finite
/// entrance animation, so the tracking screen keeps its frame rate.
class MascotMapMarker extends StatefulWidget {
  const MascotMapMarker({
    required this.variant,
    this.bearing = 0,
    this.isMoving = false,
    this.size = 54,
    super.key,
  });

  /// The mascot pose, normally [MascotVariant.ride] or [MascotVariant.car].
  final MascotVariant variant;

  /// Travel bearing in radians, where `0` points up (north) on the map.
  final double bearing;

  /// Whether the vehicle is currently travelling.
  final bool isMoving;

  /// Diameter of the marker disc.
  final double size;

  /// Total footprint including the ring margin.
  static const double margin = 7;

  /// Full box size for layout and map placement.
  static double boxSize(double size) => size + margin * 2;

  @override
  State<MascotMapMarker> createState() => _MascotMapMarkerState();
}

class _MascotMapMarkerState extends State<MascotMapMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = MascotMapMarker.boxSize(widget.size);
    return Semantics(
      label: '${widget.variant.semanticLabel}, simulated position',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final enter = Curves.easeOutBack.transform(
            _controller.value.clamp(0.0, 1.0),
          );
          return SizedBox(
            width: box,
            height: box,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isMoving)
                  Transform.translate(
                    offset: Offset(
                      -math.sin(widget.bearing) * widget.size * 0.62,
                      math.cos(widget.bearing) * widget.size * 0.62,
                    ),
                    child: _Trail(size: widget.size * 0.34),
                  ),
                Transform.rotate(
                  angle: widget.bearing,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _HeadingTick(active: widget.isMoving),
                  ),
                ),
                Transform.scale(
                  scale: 0.6 + 0.4 * enter,
                  child: Opacity(
                    opacity: enter.clamp(0.0, 1.0),
                    child: _disc(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _disc() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        boxShadow: AppShadows.raised,
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.heroWash,
          ),
          child: Center(
            child: SizedBox(
              width: widget.size * 0.84,
              height: widget.size * 0.84,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: MascotArtPainter(variant: widget.variant),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rotating compass tick that shows the travel bearing.
class _HeadingTick extends StatelessWidget {
  const _HeadingTick({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 1),
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryIndigo : AppColors.neutralGray,
          border: Border.all(color: AppColors.white, width: 1.6),
          borderRadius: const BorderRadius.all(Radius.circular(3)),
        ),
      ),
    );
  }
}

/// A faint puff trailing a moving vehicle.
class _Trail extends StatelessWidget {
  const _Trail({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryIndigo.withValues(alpha: 0.18),
      ),
    );
  }
}
