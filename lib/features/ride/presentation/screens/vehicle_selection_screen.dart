import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/schematic_map.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/entities/ride.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../../../domain/services/fare_engine.dart';
import '../../../../domain/services/route_geometry.dart';
import '../../../ride/application/ride_controller.dart';

/// Vehicle selection with live fare estimates.
///
/// The first vehicle is selected by default so the primary action is always
/// meaningful; selecting a card re-quotes immediately.
class VehicleSelectionScreen extends ConsumerWidget {
  const VehicleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideProvider);
    final ride = rideState.ride;

    // Guard: deep-linking here without a draft sends the user home rather than
    // rendering a screen with no data.
    if (ride == null) {
      return AppPage(
        title: 'Choose your ride',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'Choose a destination first, then the demo vehicle options '
                  'appear here.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Choose a demo destination',
              icon: Icons.search_rounded,
              onPressed: () =>
                  context.pushReplacementNamed(AppRoutes.destinationSearchName),
            ),
          ],
        ),
      );
    }

    return FixtureGate(
      loading: const Center(child: CircularProgressIndicator()),
      builder: (context, bundle) => _VehicleBody(ride: ride, bundle: bundle),
    );
  }
}

class _VehicleBody extends ConsumerStatefulWidget {
  const _VehicleBody({required this.ride, required this.bundle});

  final Ride ride;
  final FixtureBundle bundle;

  @override
  ConsumerState<_VehicleBody> createState() => _VehicleBodyState();
}

class _VehicleBodyState extends ConsumerState<_VehicleBody> {
  @override
  void initState() {
    super.initState();
    // Default to the cheapest option so the CTA is immediately actionable.
    if (widget.ride.vehicle == null && widget.bundle.vehicles.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(rideProvider.notifier).selectVehicle(_sortedVehicles.first);
      });
    }
  }

  List<Vehicle> get _sortedVehicles {
    final vehicles = [...widget.bundle.vehicles]
      ..sort((a, b) => a.baseFare.compareTo(b.baseFare));
    return vehicles;
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(rideProvider).ride ?? widget.ride;
    final distance = FareEngine.distanceKm(
      ride.pickup.point,
      ride.destination.point,
    );

    // Preview the currently selected vehicle on the map. Re-selecting a vehicle
    // rebuilds this screen, so the marker icon follows the choice live.
    final previewRoute = RouteGeometry.between(
      ride.pickup.point,
      ride.destination.point,
    );
    final selectedVehicle = ride.vehicle;
    final previewKind = VehicleKind.fromCategory(selectedVehicle?.category);

    return AppPage(
      title: 'Choose your ride',
      subtitle: 'Estimated demo fares for a simulated trip',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: ride.vehicle == null
                ? 'Select a demo vehicle'
                : 'Review ${Currency.format(ride.total)}',
            icon: Icons.arrow_forward_rounded,
            onPressed: ride.vehicle == null
                ? null
                : () => context.pushNamed(AppRoutes.rideReviewName),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            DemoCopy.fare,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SchematicMap(
            height: 176,
            origin: ride.pickup.point,
            destination: ride.destination.point,
            route: previewRoute,
            marker: RouteGeometry.pointAt(previewRoute, 0.24),
            vehicle: previewKind,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(previewKind.icon, size: 16, color: AppColors.primaryIndigo),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selectedVehicle == null
                      ? 'Vehicle preview'
                      : 'Preview · ${selectedVehicle.label}',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _EndpointRow(
                  icon: Icons.trip_origin_rounded,
                  color: AppColors.primaryIndigo,
                  label: 'Pickup',
                  value: ride.pickup.name,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Divider(height: 1, color: AppColors.lightBorder),
                ),
                _EndpointRow(
                  icon: Icons.place_rounded,
                  color: AppColors.electricBlue,
                  label: 'Destination',
                  value: ride.destination.name,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Vehicle options',
            subtitle: '${distance.toStringAsFixed(1)} km simulated distance',
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final vehicle in _sortedVehicles) ...[
            _VehicleCard(
              vehicle: vehicle,
              distanceKm: distance,
              selected: ride.vehicle?.id == vehicle.id,
              onTap: () =>
                  ref.read(rideProvider.notifier).selectVehicle(vehicle),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.caption),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.itemTitle,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.distanceKm,
    required this.selected,
    required this.onTap,
  });

  final Vehicle vehicle;
  final double distanceKm;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quote = FareEngine.quote(vehicle: vehicle, distanceKm: distanceKm);

    return AppCard(
      selected: selected,
      onTap: onTap,
      semanticLabel:
          '${vehicle.label}, ${vehicle.capacity} '
          '${vehicle.capacity == 1 ? 'seat' : 'seats'}, estimated fare '
          '${Currency.format(quote.total)}, ${vehicle.estimatedMinutes} '
          'minutes away',
      child: Row(
        children: [
          IconWell(
            icon: AppIcons.vehicleFor(vehicle.category),
            background: selected
                ? AppColors.primaryIndigo
                : AppColors.indigoTint,
            foreground: selected ? AppColors.white : AppColors.primaryIndigo,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.label,
                  style: AppTypography.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.capacity} '
                  '${vehicle.capacity == 1 ? 'seat' : 'seats'} · '
                  '${vehicle.estimatedMinutes} min away',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Currency.format(quote.total), style: AppTypography.amount),
              const Text('Demo estimate', style: AppTypography.caption),
            ],
          ),
          if (selected) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.primaryIndigo,
            ),
          ],
        ],
      ),
    );
  }
}
