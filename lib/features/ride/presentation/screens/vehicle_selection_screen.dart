import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/mascot.dart';
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
              Mascot(
                variant: previewKind.mascotVariant,
                size: MascotSize.small,
                animation: MascotAnimation.none,
              ),
              const SizedBox(width: AppSpacing.sm),
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
          _PromoRow(ride: ride),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Vehicle options',
            subtitle: '${distance.toStringAsFixed(1)} km simulated distance',
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final (index, vehicle) in _sortedVehicles.indexed) ...[
            AppReveal(
              key: ValueKey(vehicle.id),
              index: index,
              child: _VehicleCard(
                vehicle: vehicle,
                distanceKm: distance,
                selected: ride.vehicle?.id == vehicle.id,
                onTap: () =>
                    ref.read(rideProvider.notifier).selectVehicle(vehicle),
              ),
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

/// The "Use Promo Code" row from the reference.
///
/// Applies a bundled demo promo to the current quote. The controller owns
/// eligibility, so the row only reports the outcome it is given.
class _PromoRow extends ConsumerStatefulWidget {
  const _PromoRow({required this.ride});

  final Ride ride;

  @override
  ConsumerState<_PromoRow> createState() => _PromoRowState();
}

class _PromoRowState extends ConsumerState<_PromoRow> {
  /// Owned by the state, not by `_openSheet`, so the controller outlives the
  /// sheet's dismissal animation instead of being disposed mid-transition.
  late final TextEditingController _code = TextEditingController(
    text: widget.ride.promoCode ?? '',
  );

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _openSheet() async {
    _code.text = widget.ride.promoCode ?? '';
    final applied = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Use promo code', style: AppTypography.section),
            const SizedBox(height: AppSpacing.xxs),
            const Text(
              'These codes belong to the bundled demo dataset. Nothing is '
              'validated online.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Promo code',
                hintText: 'MOVE10',
              ),
              onSubmitted: (value) =>
                  Navigator.of(sheetContext).pop(value.trim()),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Apply code',
              icon: Icons.local_offer_rounded,
              onPressed: () =>
                  Navigator.of(sheetContext).pop(_code.text.trim()),
            ),
          ],
        ),
      ),
    );

    if (applied == null || applied.isEmpty || !mounted) return;

    final failure = ref.read(rideProvider.notifier).applyPromoCode(applied);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          failure?.message ?? 'Demo promo $applied applied to this fare.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.ride.promoCode;
    final applied = code != null && code.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: _openSheet,
      semanticLabel: applied
          ? 'Promo code $code applied. Change promo code'
          : 'Use a promo code',
      child: Row(
        children: [
          Icon(
            applied
                ? Icons.local_offer_rounded
                : Icons.confirmation_number_outlined,
            size: 20,
            color: applied ? AppColors.success : AppColors.primaryIndigo,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              applied ? 'Promo $code applied' : 'Use Promo Code',
              style: AppTypography.itemTitle.copyWith(
                color: applied ? AppColors.success : AppColors.deepNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (applied)
            TextButton(
              onPressed: () => ref.read(rideProvider.notifier).clearPromo(),
              child: const Text('Remove'),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.neutralGray,
            ),
        ],
      ),
    );
  }
}
