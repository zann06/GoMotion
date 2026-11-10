import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/ride.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../../ride/application/ride_controller.dart';
import '../widgets/driver_card.dart';

/// The radar search, driver reveal, and driver-approach screen.
///
/// The clock drives every stage change; this widget only renders the current
/// stage and lists explicitly for it. Once the driver arrives it offers the
/// pickup confirmation, which is what starts the trip.
class RideMatchingScreen extends ConsumerWidget {
  const RideMatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rideProvider);
    final ride = state.ride;

    if (ride == null) {
      return AppPage(
        title: 'Finding your driver',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message: 'There is no active demo ride to match right now.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Start a new demo ride',
              icon: Icons.directions_car_rounded,
              onPressed: () => context.goNamed(AppRoutes.destinationSearchName),
            ),
          ],
        ),
      );
    }

    return FixtureGate(
      loading: const Center(child: CircularProgressIndicator()),
      builder: (context, bundle) => _MatchingBody(ride: ride, bundle: bundle),
    );
  }
}

class _MatchingBody extends ConsumerStatefulWidget {
  const _MatchingBody({required this.ride, required this.bundle});

  final Ride ride;
  final FixtureBundle bundle;

  @override
  ConsumerState<_MatchingBody> createState() => _MatchingBodyState();
}

class _MatchingBodyState extends ConsumerState<_MatchingBody> {
  /// Pushes to tracking as soon as the trip actually begins.
  void _syncRoute(Ride ride) {
    if (ride.stage == RideStage.inProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushReplacementNamed(AppRoutes.rideTrackingName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideProvider);
    final ride = state.ride ?? widget.ride;
    final motion = ref.watch(reduceMotionProvider);
    _syncRoute(ride);

    final driver = ride.driverId == null
        ? null
        : widget.bundle.driver(ride.driverId!);
    final isSearching = ride.stage == RideStage.searching;
    final hasDriver = driver != null;
    final canStart = ride.stage == RideStage.driverArriving;

    return AppPage(
      title: isSearching ? 'Finding your driver' : 'Your demo driver',
      subtitle: isSearching
          ? 'Searching the local demo dataset'
          : 'Driver information is fictional sample data',
      // Return to the dashboard rather than a stale vehicle selection; the
      // search keeps running and home surfaces it as an active journey.
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      footer: hasDriver
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: canStart
                      ? 'Confirm pickup and start'
                      : 'Waiting for the driver to arrive…',
                  icon: canStart ? Icons.play_arrow_rounded : null,
                  onPressed: canStart
                      ? () {
                          final failure = ref
                              .read(rideProvider.notifier)
                              .startTrip();
                          if (failure != null) {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(
                                content: Text(failure.message),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.xxs),
                TextButton.icon(
                  onPressed: () => _confirmCancel(context),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel demo ride'),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TonalButton(
                  label: 'Cancel search',
                  icon: Icons.close_rounded,
                  onPressed: () => _confirmCancel(context),
                ),
              ],
            ),
      body: AnimatedSwitcher(
        // The radar hands over to the driver card instead of being replaced in
        // a single frame. `AnimatedSwitcher` is finite, so reduced motion just
        // shortens the cross-fade rather than removing it.
        duration: motion.resolve(AppDuration.enter),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: isSearching
            ? const Column(
                key: ValueKey('matching-search'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.lg),
                  _Radar(),
                  SizedBox(height: AppSpacing.lg),
                  _SearchingCopy(),
                ],
              )
            : Column(
                key: const ValueKey('matching-driver'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const SizedBox(height: 220),
                  const SizedBox(height: AppSpacing.lg),
                  if (hasDriver) ...[
                    DriverCard(
                      driver: driver,
                      vehicle: ride.vehicle,
                      status: ride.stage == RideStage.driverArriving
                          ? DemoCopy.arrival
                          : 'On the way',
                      showCall: false,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ApproachSteps(stage: ride.stage),
                    const SizedBox(height: AppSpacing.md),
                    const AppNotice(
                      message:
                          'Driver, vehicle, and arrival times are simulated from '
                          'bundled demo data. No GPS is used.',
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this demo ride?'),
        content: const Text(
          'The simulated journey will stop and be recorded as cancelled. '
          'No payment is involved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep ride'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(rideProvider.notifier).cancel();
    context.goNamed(AppRoutes.homeName);
  }
}

/// The animated radar sweep. Holds still when motion is reduced.
class _Radar extends ConsumerWidget {
  const _Radar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);

    return Semantics(
      label: 'Searching for a demo driver',
      liveRegion: true,
      child: SizedBox(
        height: 220,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              motion.allowLoops ? const _SpinningRadar() : const _StaticRadar(),
              const Mascot(
                variant: MascotVariant.ride,
                size: MascotSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinningRadar extends StatefulWidget {
  const _SpinningRadar();

  @override
  State<_SpinningRadar> createState() => _SpinningRadarState();
}

class _SpinningRadarState extends State<_SpinningRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDuration.radar,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: const Size(220, 220),
        painter: _RadarPainter(sweep: _controller.value),
      ),
    );
  }
}

class _StaticRadar extends StatelessWidget {
  const _StaticRadar();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(220, 220),
      painter: _RadarPainter(sweep: 0.18),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.sweep});

  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final bounds = Rect.fromCircle(center: center, radius: maxRadius);

    // Ground wash: a radial falloff instead of a flat disc, so the radar melts
    // into the page rather than sitting on it as a pasted circle.
    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.white,
            AppColors.blueTint.withValues(alpha: 0.62),
            AppColors.blueTint.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(bounds),
    );

    // Concentric rings: the inner ones are fainter, which reads as depth.
    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3) * 0.94,
        Paint()
          ..color = AppColors.primaryIndigo.withValues(
            alpha: 0.10 + (3 - i) * 0.03,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Crosshair ticks at the four compass points.
    final tick = Paint()
      ..color = AppColors.primaryIndigo.withValues(alpha: 0.16)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final angle = math.pi / 4 + i * math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * (maxRadius * 0.66),
        center + Offset(math.cos(angle), math.sin(angle)) * (maxRadius * 0.74),
        tick,
      );
    }

    final startAngle = sweep * math.pi * 2;

    // The sweep wedge fades as it trails the leading edge: drawn as stacked
    // arcs of decreasing opacity instead of one flat pie slice.
    const segments = 14;
    const spread = 1.15;
    for (var i = 0; i < segments; i++) {
      final t = i / segments;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            bounds,
            startAngle - spread * t,
            -spread / segments * 1.25,
            false,
          )
          ..close(),
        Paint()
          ..color = AppColors.primaryIndigo.withValues(
            alpha: 0.010 + 0.11 * (1 - t) * (1 - t),
          ),
      );
    }

    // Leading edge: a soft glow, a crisp line, and a bright tip so the sweep
    // direction is unmistakable without a hard vector look.
    final tip =
        center +
        Offset(math.cos(startAngle), math.sin(startAngle)) * (maxRadius * 0.93);
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = AppColors.primaryIndigo.withValues(alpha: 0.30)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.primaryIndigo.withValues(alpha: 0.25),
            AppColors.electricBlue,
          ],
        ).createShader(Rect.fromPoints(center, tip))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 4.2, Paint()..color = AppColors.white);
    canvas.drawCircle(tip, 2.2, Paint()..color = AppColors.electricBlue);

    // Hub.
    canvas.drawCircle(
      center,
      9,
      Paint()..color = AppColors.primaryIndigo.withValues(alpha: 0.14),
    );
    canvas.drawCircle(center, 6, Paint()..color = AppColors.white);
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = AppColors.primaryIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.sweep != sweep;
}

class _SearchingCopy extends StatelessWidget {
  const _SearchingCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Matching you with a demo driver',
          style: AppTypography.section,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          DemoCopy.simulation,
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A three-step progress list for the driver approach.
class _ApproachSteps extends StatelessWidget {
  const _ApproachSteps({required this.stage});

  final RideStage stage;

  @override
  Widget build(BuildContext context) {
    final arrived = stage == RideStage.driverArriving;
    final steps = [
      (label: 'Driver assigned', done: true),
      (label: DemoCopy.arrival, done: arrived),
      (label: 'Trip start waiting for you', done: false),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          for (final step in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    step.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: step.done
                        ? AppColors.success
                        : AppColors.neutralGray,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      step.label,
                      style: AppTypography.bodyMuted.copyWith(
                        color: step.done
                            ? AppColors.deepNavy
                            : AppColors.neutralGray,
                      ),
                    ),
                  ),
                  Text(
                    step.done ? 'Done' : 'Pending',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
