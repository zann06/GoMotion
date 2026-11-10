import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/schematic_map.dart';
import '../../../../domain/entities/ride.dart';
import '../../../../domain/services/route_geometry.dart';
import '../../../ride/application/ride_controller.dart';
import '../../../ride/presentation/widgets/driver_card.dart';

/// Live trip simulation: marker movement, ETA, and completion.
///
/// The marker position is derived from the ride's `progress`, which the
/// simulation clock advances. Once the ride completes this screen forwards to
/// payment, so the user never sits on a finished trip.
class RideTrackingScreen extends ConsumerWidget {
  const RideTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideProvider).ride;

    if (ride == null) {
      return AppPage(
        title: 'Your trip',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(message: 'There is no active demo trip to track.'),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Start a new demo ride',
              icon: Icons.directions_car_rounded,
              onPressed: () => context.goNamed(AppRoutes.homeName),
            ),
          ],
        ),
      );
    }

    // Forward to payment once the trip completes, and to the receipt when paid.
    if (ride.stage == RideStage.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacementNamed(AppRoutes.ridePaymentName);
      });
    }

    return _TrackingBody(ride: ride);
  }
}

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = RouteGeometry.between(
      ride.pickup.point,
      ride.destination.point,
    );
    final marker = RouteGeometry.pointAt(route, ride.progress);
    final bearing = RouteGeometry.bearingAt(route, ride.progress);
    final mascot = MascotVariant.forRideCategory(ride.vehicle?.category);
    final travelling = ride.stage == RideStage.inProgress;

    // Resolves the assigned driver once, so the card and the ETA badge share it.
    final driverId = ride.driverId;
    final driver = driverId == null
        ? null
        : ref.watch(fixtureBundleProvider).value?.driver(driverId);
    final vehicle = ride.vehicle;

    // The reference keeps the remaining time and distance pinned over the map,
    // so the two numbers that matter are readable without scrolling.
    final remainingKm = ride.distanceKm * (1 - ride.progress);
    final remainingMinutes = vehicle == null
        ? 0
        : (vehicle.estimatedMinutes * (1 - ride.progress)).ceil();

    return AppPage(
      title: 'On your way',
      subtitle: 'Arriving at ${ride.destination.name}',
      padded: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SchematicMap(
                height: 260,
                origin: ride.pickup.point,
                destination: ride.destination.point,
                route: route,
                marker: marker,
                vehicle: VehicleKind.fromCategory(vehicle?.category),
                markerMascot: mascot,
                bearing: bearing,
                isMoving: travelling,
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _EtaBadge(
                  minutes: remainingMinutes,
                  kilometres: remainingKm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (driver != null) ...[
            DriverCard(driver: driver, vehicle: vehicle, status: 'On the way'),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Mascot(
                      variant: mascot,
                      size: MascotSize.small,
                      animation: MascotAnimation.none,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Simulated progress',
                        style: AppTypography.itemTitle,
                      ),
                    ),
                    AppAnimatedCounter(
                      value: ride.progress * 100,
                      format: (value) => '${value.round()}%',
                      style: AppTypography.amount,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: ride.progress,
                  semanticLabel: 'Trip progress',
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${ride.vehicle?.label ?? 'Demo ride'} · '
                  '${ride.distanceKm.toStringAsFixed(1)} km simulated',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(DemoCopy.simulation, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.pickup.name, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(ride.pickup.addressLabel, style: AppTypography.caption),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),
                Text(ride.destination.name, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(
                  ride.destination.addressLabel,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'This trip runs entirely on your device from bundled demo '
                'data. No live tracking is performed.',
          ),
        ],
      ),
    );
  }
}

/// The remaining time and distance, floated over the map.
///
/// Mirrors the reference's "2 min / 0.8 km" chip: the two live numbers stay
/// legible against the map without competing with the route itself.
class _EtaBadge extends StatelessWidget {
  const _EtaBadge({required this.minutes, required this.kilometres});

  final int minutes;
  final double kilometres;

  @override
  Widget build(BuildContext context) {
    final label =
        '$minutes min remaining, ${kilometres.toStringAsFixed(1)} kilometres';

    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.tile,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A0E2A6E),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$minutes min',
              style: AppTypography.itemTitle.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${kilometres.toStringAsFixed(1)} km left',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
