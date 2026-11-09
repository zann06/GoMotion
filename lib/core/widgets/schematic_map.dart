import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/fixtures.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// The offline schematic map.
///
/// This is an illustrated abstraction, not a geographic map: no tiles, no
/// network, no GPS. It paints a soft ground, a grid of roads, two park blocks,
/// an optional route polyline, and origin/destination pins. Every coordinate is
/// a normalised [MapPoint].
class SchematicMap extends StatelessWidget {
  const SchematicMap({
    this.route = const [],
    this.origin,
    this.destination,
    this.marker,
    this.showDemoLabel = true,
    this.height = 220,
    this.borderRadius = AppRadius.card,
    super.key,
  });

  /// Ordered polyline points for the simulated route.
  final List<MapPoint> route;

  /// Origin pin, usually the pickup location.
  final MapPoint? origin;

  /// Destination pin.
  final MapPoint? destination;

  /// Animated marker position, e.g. the approaching driver.
  final MapPoint? marker;

  /// Whether to render the "DEMO MAP" chip.
  final bool showDemoLabel;

  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Illustrated demo map. Not a real map and not live GPS. '
          'Shows a simulated route between demo points.',
      container: true,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _MapPainter(
                    route: route,
                    origin: origin,
                    destination: destination,
                    marker: marker,
                  ),
                ),
              ),
              if (showDemoLabel)
                const Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: _DemoMapChip(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoMapChip extends StatelessWidget {
  const _DemoMapChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.chip,
      ),
      child: Text(
        'DEMO MAP',
        style: AppTypography.pill.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

/// Paints the schematic ground, roads, parks, route, and pins.
class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.route,
    required this.origin,
    required this.destination,
    required this.marker,
  });

  final List<MapPoint> route;
  final MapPoint? origin;
  final MapPoint? destination;
  final MapPoint? marker;

  // Deterministic park blocks, expressed as fractions of the canvas.
  static const List<Rect> _parks = [
    Rect.fromLTWH(0.06, 0.10, 0.24, 0.18),
    Rect.fromLTWH(0.68, 0.60, 0.24, 0.19),
  ];

  // Road positions as fractions; slight jitter keeps it hand-drawn, not rigid.
  static const List<double> _verticalRoads = [
    0.05,
    0.22,
    0.39,
    0.56,
    0.73,
    0.90,
  ];
  static const List<double> _horizontalRoads = [0.14, 0.33, 0.52, 0.71, 0.90];

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas.drawRect(bounds, Paint()..color = AppColors.mapGround);

    // Park blocks use the semantic success tint, which the design system
    // explicitly permits for map illustration detail.
    final parkPaint = Paint()..color = AppColors.successTint;
    for (final park in _parks) {
      final rect = Rect.fromLTWH(
        park.left * size.width,
        park.top * size.height,
        park.width * size.width,
        park.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        parkPaint,
      );
    }

    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeCap = StrokeCap.round;

    for (final (index, x) in _verticalRoads.indexed) {
      roadPaint.strokeWidth = index.isEven ? 7 : 4;
      final jitter = math.sin(index * 1.7) * size.width * 0.012;
      canvas.drawLine(
        Offset(x * size.width + jitter, -8),
        Offset(x * size.width - jitter, size.height + 8),
        roadPaint,
      );
    }
    for (final (index, y) in _horizontalRoads.indexed) {
      roadPaint.strokeWidth = index.isEven ? 7 : 4;
      final jitter = math.cos(index * 1.3) * size.height * 0.02;
      canvas.drawLine(
        Offset(-8, y * size.height + jitter),
        Offset(size.width + 8, y * size.height - jitter),
        roadPaint,
      );
    }

    final routePaint = Paint()
      ..color = AppColors.primaryIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (route.length > 1) {
      final path = Path();
      final points = [for (final p in route) _toOffset(p, size)];
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      // A soft halo keeps the route readable over bright roads.
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, routePaint);
    }

    final pinBorder = Paint()
      ..color = AppColors.primaryIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final pinFill = Paint()..color = AppColors.white;

    void drawPin(MapPoint point) {
      final o = _toOffset(point, size);
      canvas.drawCircle(o, 7, pinFill);
      canvas.drawCircle(o, 7, pinBorder);
    }

    if (origin != null) drawPin(origin!);
    if (destination != null) drawPin(destination!);

    if (marker != null) {
      final o = _toOffset(marker!, size);
      canvas.drawCircle(o, 13, Paint()..color = AppColors.primaryIndigo);
      canvas.drawCircle(o, 5, Paint()..color = AppColors.white);
    }
  }

  Offset _toOffset(MapPoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.marker != marker ||
        oldDelegate.origin != origin ||
        oldDelegate.destination != destination ||
        !_listEquals(oldDelegate.route, route);
  }

  bool _listEquals(List<MapPoint> a, List<MapPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
