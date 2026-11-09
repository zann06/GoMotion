import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../ride/application/ride_controller.dart';

/// Fare review, promo application, and booking confirmation.
class RideReviewScreen extends ConsumerStatefulWidget {
  const RideReviewScreen({super.key});

  @override
  ConsumerState<RideReviewScreen> createState() => _RideReviewScreenState();
}

class _RideReviewScreenState extends ConsumerState<RideReviewScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;
  bool _submitting = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() => _promoError = 'Enter a demo promo code to apply.');
      return;
    }

    final failure = ref.read(rideProvider.notifier).applyPromoCode(code);
    setState(() {
      _promoError = failure?.message;
    });

    if (failure == null) {
      _promoController.clear();
      _showMessage('Demo promo applied.');
    }
  }

  void _removePromo() {
    ref.read(rideProvider.notifier).clearPromo();
    setState(() => _promoError = null);
    _showMessage('Demo promo removed.');
  }

  Future<void> _confirmBooking() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final failure = ref.read(rideProvider.notifier).confirmBooking();
    if (!mounted) return;

    setState(() => _submitting = false);

    if (failure != null) {
      _showMessage(failure.message);
      return;
    }

    // Replace so Back from matching does not return to a stale review screen.
    context.pushReplacementNamed(AppRoutes.rideMatchingName);
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = ref.watch(rideProvider).ride;

    if (ride == null || ride.fare == null || ride.vehicle == null) {
      return AppPage(
        title: 'Review your ride',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'This demo booking has no draft to review. Choose a '
                  'destination and vehicle to start again.',
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

    final fare = ride.fare!;
    final vehicle = ride.vehicle!;

    return AppPage(
      title: 'Review your ride',
      subtitle: 'Check the details before you book this demo ride',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Confirm demo booking',
            icon: Icons.check_rounded,
            loading: _submitting,
            onPressed: _confirmBooking,
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'No payment is taken now — this is a local simulation.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'Demo booking', tone: PillTone.brand),
                const SizedBox(height: AppSpacing.sm),
                _RouteLine(
                  pickup: ride.pickup.name,
                  destination: ride.destination.name,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${vehicle.label} · '
                  '${fare.distanceKm.toStringAsFixed(1)} km simulated',
                  style: AppTypography.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Demo fare estimate'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Base fare',
                  value: Currency.format(fare.baseFare),
                ),
                DetailRow(
                  label: 'Distance (${fare.distanceKm.toStringAsFixed(1)} km)',
                  value: Currency.format(fare.distanceFare),
                ),
                if (fare.discount > 0)
                  DetailRow(
                    label: 'Promo ${fare.promoCode ?? ''}',
                    value: '− ${Currency.format(fare.discount)}',
                    valueColor: AppColors.success,
                  ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Estimated total',
                  value: Currency.format(fare.total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(DemoCopy.fare, style: AppTypography.caption),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Promo code',
            subtitle: 'Try MOVE10 or FIRST5 from the demo dataset',
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Demo promo code',
                        hint: 'e.g. MOVE10',
                        controller: _promoController,
                        errorText: _promoError,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _applyPromo(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 96,
                      child: TonalButton(
                        label: ride.promoCode == null ? 'Apply' : 'Replace',
                        onPressed: _applyPromo,
                      ),
                    ),
                  ],
                ),
                if (ride.promoCode != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          '${ride.promoCode} applied to this demo fare.',
                          style: AppTypography.caption,
                        ),
                      ),
                      TextButton(
                        onPressed: _removePromo,
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            tone: NoticeTone.info,
            message:
                'Every amount here is a fictional estimate. Nothing is charged '
                'and no real transport service is contacted.',
          ),
        ],
      ),
    );
  }
}

/// The pickup → destination vertical line used on review and receipt screens.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trip_origin_rounded,
              size: 14,
              color: AppColors.primaryIndigo,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                pickup,
                style: AppTypography.itemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: SizedBox(
            height: 14,
            child: VerticalDivider(width: 2, color: AppColors.lightBorder),
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.place_rounded,
              size: 14,
              color: AppColors.electricBlue,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                destination,
                style: AppTypography.itemTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
