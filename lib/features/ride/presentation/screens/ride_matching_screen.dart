import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/entities/ride.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../../ride/application/ride_controller.dart';

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          if (isSearching) const _Radar() else const SizedBox(height: 220),
          const SizedBox(height: AppSpacing.lg),
          if (isSearching)
            const _SearchingCopy()
          else if (hasDriver)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DriverCard(
                  driver: driver,
                  vehicleLabel: ride.vehicle?.label ?? 'Demo vehicle',
                  stage: ride.stage,
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
            ),
        ],
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
          child: motion.allowLoops
              ? const _SpinningRadar()
              : const _StaticRadar(),
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

    for (var i = 3; i >= 1; i--) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3),
        Paint()
          ..color = AppColors.indigoTint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    canvas.drawCircle(
      center,
      maxRadius,
      Paint()..color = AppColors.blueTint.withValues(alpha: 0.55),
    );

    // A soft wedge trailing the leading edge.
    final startAngle = sweep * 6.28318530718;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      startAngle,
      0.9,
      true,
      Paint()..color = AppColors.primaryIndigo.withValues(alpha: 0.16),
    );

    canvas.drawLine(
      center,
      Offset(
        center.dx + maxRadius * 0.96 * _cos(startAngle),
        center.dy + maxRadius * 0.96 * _sin(startAngle),
      ),
      Paint()
        ..color = AppColors.primaryIndigo
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 7, Paint()..color = AppColors.primaryIndigo);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.white);
  }

  double _cos(double radians) => math.cos(radians);

  double _sin(double radians) => math.sin(radians);

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

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.vehicleLabel,
    required this.stage,
  });

  final Driver driver;
  final String vehicleLabel;
  final RideStage stage;

  @override
  Widget build(BuildContext context) {
    final arriving = stage == RideStage.driverArriving;
    return AppCard(
      semanticLabel:
          '${DemoCopy.driver} ${driver.displayName}, rating '
          '${driver.rating}, $vehicleLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.tile,
                child: Image.asset(
                  ImageAssets.resolve(driver.avatarAsset),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  // A missing optional avatar degrades to an icon, never a crash.
                  errorBuilder: (context, error, stack) => Container(
                    width: 56,
                    height: 56,
                    color: AppColors.indigoTint,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryIndigo,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.displayName, style: AppTypography.itemTitle),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${driver.rating} · '
                          '${driver.completedDemoTrips} demo trips',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Vehicle', value: vehicleLabel),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Plate',
                  value:
                      '${DemoCopy.plate} ${driver.seedOrder.toString().padLeft(3, '0')}',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Status',
                  value: arriving ? 'Arrived' : 'On the way',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(DemoCopy.driver, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.itemTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
