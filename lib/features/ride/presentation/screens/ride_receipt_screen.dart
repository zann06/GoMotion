import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/ride.dart';
import '../../../ride/application/ride_controller.dart';

/// The demo receipt, with an optional star rating.
///
/// The receipt stays reachable from Activity after completion, so it renders
/// from the ride state rather than from a one-shot route argument.
class RideReceiptScreen extends ConsumerWidget {
  const RideReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideProvider).ride;

    if (ride == null ||
        ride.stage != RideStage.paid && ride.stage != RideStage.rated) {
      return AppPage(
        title: 'Demo receipt',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'This demo receipt is no longer available in the current '
                  'session. Completed journeys remain listed in Activity.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Open activity',
              icon: Icons.receipt_long_rounded,
              onPressed: () => context.goNamed(AppRoutes.activityName),
            ),
          ],
        ),
      );
    }

    return AppPage(
      title: 'Demo receipt',
      subtitle: 'A fictional record of your simulated ride',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ride.stage == RideStage.paid)
            PrimaryButton(
              label: 'Skip rating and finish',
              onPressed: () => context.goNamed(AppRoutes.homeName),
            )
          else
            PrimaryButton(
              label: 'Back to home',
              icon: Icons.home_rounded,
              onPressed: () => context.goNamed(AppRoutes.homeName),
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
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.successTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Demo ride paid', style: AppTypography.section),
                          Text(
                            'Payment recorded locally',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DetailRow(
                  label: 'Route',
                  value: '${ride.pickup.name} → ${ride.destination.name}',
                ),
                DetailRow(
                  label: 'Vehicle',
                  value: ride.vehicle?.label ?? 'Demo vehicle',
                ),
                DetailRow(
                  label: 'Distance',
                  value: '${ride.distanceKm.toStringAsFixed(1)} km simulated',
                ),
                DetailRow(
                  label: 'Payment',
                  value: ride.paymentMethod == PaymentMethod.demoWallet
                      ? 'Demo wallet'
                      : 'Cash',
                ),
                DetailRow(label: 'Journey id', value: ride.id),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Total paid',
                  value: Currency.format(ride.total),
                  emphasize: true,
                ),
                const DetailRow(
                  label: 'Demo points earned',
                  value: '+${AppInfo.demoPointsPerJourney} ${DemoCopy.points}',
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(DemoCopy.transaction, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (ride.stage == RideStage.paid)
            _RatingCard(
              rating: ride.rating,
              onSubmit: (stars) {
                ref.read(rideProvider.notifier).submitRating(stars);
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                    content: Text('Thanks — your demo rating was saved.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )
          else
            AppNotice(
              tone: NoticeTone.success,
              message: ride.rating == null
                  ? 'This demo ride is complete.'
                  : 'You rated this demo ride ${ride.rating} out of 5.',
            ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatefulWidget {
  const _RatingCard({required this.rating, required this.onSubmit});

  final int? rating;
  final ValueChanged<int> onSubmit;

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _selected = 0;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.rating ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AppNotice(
        tone: NoticeTone.success,
        message: 'You rated this demo ride $_selected out of 5.',
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rate your demo driver', style: AppTypography.section),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Ratings are stored locally for this session only.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var star = 1; star <= 5; star++)
                Semantics(
                  button: true,
                  selected: star <= _selected,
                  label: 'Rate $star out of 5',
                  child: IconButton(
                    onPressed: () => setState(() => _selected = star),
                    icon: Icon(
                      star <= _selected
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: star <= _selected
                          ? AppColors.warning
                          : AppColors.neutralGray,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TonalButton(
            label: 'Submit demo rating',
            onPressed: _selected == 0
                ? null
                : () {
                    setState(() => _submitted = true);
                    widget.onSubmit(_selected);
                  },
          ),
        ],
      ),
    );
  }
}
