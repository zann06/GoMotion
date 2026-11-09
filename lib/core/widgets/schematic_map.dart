import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/reduced_motion_provider.dart';
import '../../domain/entities/fixtures.dart';
import '../constants/app_colors.dart';
import '../constants/app_icons.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/mascot_assets.dart';
import 'mascot_map_marker.dart';

/// A nearby vehicle drawn on the schematic map, e.g. an idle demo car.
@immutable
class MapVehiclePin {
  const MapVehiclePin({required this.point, required this.kind});

  final MapPoint point;
  final VehicleKind kind;
}

/// The offline schematic map.
///
/// This is an illustrated abstraction, not a geographic map: no tiles, no
/// network, no GPS. It paints a soft ground, city blocks, parks, a road grid, an
/// optional route polyline, origin/destination pins, and an optional vehicle
/// marker whose icon matches the selected ride vehicle.
///
/// Every coordinate is a normalised [MapPoint].
class SchematicMap extends ConsumerWidget {
  const SchematicMap({
    this.route = const [],
    this.origin,
    this.destination,
    this.marker,
    this.vehicle,
    this.markerIcon,
    this.markerMascot,
    this.bearing = 0,
    this.isMoving = false,
    this.nearby = const [],
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

  /// Animated marker position, e.g. the approaching driver or courier. The
  /// marker eases to each new position instead of jumping.
  final MapPoint? marker;

  /// Vehicle shape shown inside the marker. Defaults to a car.
  final VehicleKind? vehicle;

  /// Overrides the marker with a plain icon, e.g. a legacy courier glyph.
  final IconData? markerIcon;

  /// Overrides the mascot pose used for the vehicle marker.
  final MascotVariant? markerMascot;

  /// Travel bearing in radians, where `0` points up (north).
  final double bearing;

  /// Whether the marker is currently travelling.
  final bool isMoving;

  /// Idle nearby vehicles, drawn as small secondary markers.
  final List<MapVehiclePin> nearby;

  /// Whether to render the "DEMO MAP" chip.
  final bool showDemoLabel;

  final double height;
  final BorderRadius borderRadius;

  IconData get _resolvedMarkerIcon =>
      markerIcon ?? (vehicle ?? VehicleKind.car).icon;

  String get _markerLabel =>
      markerIcon != null ? 'demo courier' : (vehicle ?? VehicleKind.car).label;

  /// The mascot pose for the marker, or null when a plain icon is used.
  ///
  /// The mascot vehicle is the primary treatment; [markerIcon] is the escape
  /// hatch for callers that still want a bare glyph.
  MascotVariant? get _resolvedMascot {
    if (markerIcon != null) return null;
    final explicit = markerMascot;
    if (explicit != null) return explicit;
    return vehicle?.mascotVariant;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    final mascot = _resolvedMascot;

    return Semantics(
      label:
          'Illustrated demo map. Not a real map and not live GPS. '
          'Shows a simulated route between demo points'
          '${marker != null ? ' and a $_markerLabel marker' : ''}.',
      container: true,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, height);
              final markerExtent = mascot == null
                  ? 58.0
                  : MascotMapMarker.boxSize(54);
              final markerWidget = mascot == null
                  ? _VehicleMarker(
                      icon: _resolvedMarkerIcon,
                      label: _markerLabel,
                    )
                  : MascotMapMarker(
                      variant: mascot,
                      bearing: bearing,
                      isMoving: isMoving,
                    );
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _MapPainter(
                          route: route,
                          origin: origin,
                          destination: destination,
                        ),
                      ),
                    ),
                  ),
                  for (final pin in nearby)
                    _at(size, pin.point, 32, _NearbyVehicle(kind: pin.kind)),
                  if (marker != null)
                    AnimatedPositioned(
                      duration: motion.resolve(AppDuration.value),
                      curve: Curves.linear,
                      left: _left(size, marker!, markerExtent),
                      top: _top(size, marker!, markerExtent),
                      width: markerExtent,
                      height: markerExtent,
                      child: markerWidget,
                    ),
                  if (showDemoLabel)
                    const Positioned(
                      left: AppSpacing.sm,
                      top: AppSpacing.sm,
                      child: _DemoMapChip(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Centres a normalised point inside the map, clamped so a marker of
  /// [extent] never spills past the edge.
  double _left(Size size, MapPoint point, double extent) =>
      (point.x * size.width - extent / 2)
          .clamp(0.0, math.max(0, size.width - extent))
          .toDouble();

  double _top(Size size, MapPoint point, double extent) =>
      (point.y * size.height - extent / 2)
          .clamp(0.0, math.max(0, size.height - extent))
          .toDouble();

  /// Places [child] centred on a normalised point, clamped inside the map.
  Widget _at(Size size, MapPoint point, double extent, Widget child) {
    return Positioned(
      left: _left(size, point, extent),
      top: _top(size, point, extent),
      width: extent,
      height: extent,
      child: child,
    );
  }
}

/// A white chip carrying the selected vehicle icon, with a soft halo.
class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryIndigo.withValues(alpha: 0.16),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryIndigo, width: 2.5),
                boxShadow: AppShadows.raised,
              ),
              child: Icon(icon, size: 21, color: AppColors.primaryIndigo),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small secondary marker for an idle nearby vehicle.
class _NearbyVehicle extends StatelessWidget {
  const _NearbyVehicle({required this.kind});

  final VehicleKind kind;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.mapBlockAlt, width: 1.5),
          boxShadow: AppShadows.card,
        ),
        child: Icon(
          kind.icon,
          size: 15,
          color: AppColors.primaryIndigo.withValues(alpha: 0.8),
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
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 12,
            color: AppColors.primaryIndigo,
          ),
          const SizedBox(width: 4),
          Text(
            'DEMO MAP',
            style: AppTypography.pill.copyWith(
              letterSpacing: 0.8,
              color: AppColors.deepBlue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the schematic ground, blocks, parks, roads, route, and pins.
class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.route,
    required this.origin,
    required this.destination,
  });

  final List<MapPoint> route;
  final MapPoint? origin;
  final MapPoint? destination;

  /// Deterministic city blocks as fractions of the canvas.
  static const List<Rect> _blocks = [
    Rect.fromLTWH(0.25, 0.17, 0.11, 0.12),
    Rect.fromLTWH(0.59, 0.17, 0.11, 0.12),
    Rect.fromLTWH(0.08, 0.36, 0.11, 0.12),
    Rect.fromLTWH(0.42, 0.36, 0.11, 0.12),
    Rect.fromLTWH(0.76, 0.36, 0.10, 0.12),
    Rect.fromLTWH(0.25, 0.75, 0.11, 0.11),
    Rect.fromLTWH(0.59, 0.55, 0.11, 0.12),
  ];

  static const List<Rect> _parks = [
    Rect.fromLTWH(0.08, 0.55, 0.13, 0.13),
    Rect.fromLTWH(0.76, 0.72, 0.16, 0.14),
  ];

  static const List<double> _verticalRoads = [0.05, 0.22, 0.39, 0.56, 0.73];
  static const List<double> _horizontalRoads = [0.14, 0.33, 0.52, 0.71, 0.90];

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    // A gentle diagonal wash keeps the ground from looking flat.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mapGround, Color(0xFFF2F6FE)],
        ).createShader(bounds),
    );

    // City blocks.
    for (final (index, block) in _blocks.indexed) {
      final rect = Rect.fromLTWH(
        block.left * size.width,
        block.top * size.height,
        block.width * size.width,
        block.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..color = index.isEven ? AppColors.mapBlock : AppColors.mapBlockAlt,
      );
    }

    // Park blocks use the semantic success tint, which the design system
    // explicitly permits for map illustration detail.
    for (final park in _parks) {
      final rect = Rect.fromLTWH(
        park.left * size.width,
        park.top * size.height,
        park.width * size.width,
        park.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        Paint()..color = AppColors.successTint,
      );
    }

    final casing = Paint()
      ..color = AppColors.mapRoadCasing
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = AppColors.mapRoad
      ..strokeCap = StrokeCap.round;

    for (final (index, x) in _verticalRoads.indexed) {
      final width = index.isEven ? 10.0 : 7.0;
      final jitter = math.sin(index * 1.7) * size.width * 0.012;
      final from = Offset(x * size.width + jitter, -8);
      final to = Offset(x * size.width - jitter, size.height + 8);
      casing.strokeWidth = width + 4;
      road.strokeWidth = width;
      canvas.drawLine(from, to, casing);
      canvas.drawLine(from, to, road);
    }
    for (final (index, y) in _horizontalRoads.indexed) {
      final width = index.isEven ? 10.0 : 7.0;
      final jitter = math.cos(index * 1.3) * size.height * 0.02;
      final from = Offset(-8, y * size.height + jitter);
      final to = Offset(size.width + 8, y * size.height - jitter);
      casing.strokeWidth = width + 4;
      road.strokeWidth = width;
      canvas.drawLine(from, to, casing);
      canvas.drawLine(from, to, road);
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
          ..color = AppColors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(path, routePaint);
    }

    if (origin != null) _drawOrigin(canvas, _toOffset(origin!, size));
    if (destination != null) {
      _drawDestination(canvas, _toOffset(destination!, size));
    }
  }

  void _drawOrigin(Canvas canvas, Offset o) {
    canvas.drawCircle(o, 8, Paint()..color = AppColors.white);
    canvas.drawCircle(
      o,
      8,
      Paint()
        ..color = AppColors.deepBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawCircle(o, 3, Paint()..color = AppColors.deepBlue);
  }

  void _drawDestination(Canvas canvas, Offset o) {
    canvas.drawCircle(o, 10, Paint()..color = AppColors.white);
    canvas.drawCircle(o, 10, Paint()..color = AppColors.primaryIndigo);
    canvas.drawCircle(o, 4, Paint()..color = AppColors.white);
  }

  Offset _toOffset(MapPoint p, Size size) =>
      Offset(p.x * size.width, p.y * size.height);

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.origin != origin ||
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
