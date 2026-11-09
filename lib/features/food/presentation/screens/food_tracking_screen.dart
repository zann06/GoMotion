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
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/schematic_map.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/entities/food_order.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../application/food_controller.dart';

/// Courier matching, preparation, and delivery tracking.
class FoodTrackingScreen extends ConsumerWidget {
  const FoodTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(foodProvider).order;

    if (order == null) {
      return AppPage(
        title: 'Your demo order',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message: 'There is no active demo food order to track.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Browse demo restaurants',
              icon: Icons.restaurant_rounded,
              onPressed: () => context.goNamed(AppRoutes.foodName),
            ),
          ],
        ),
      );
    }

    if (order.stage == FoodStage.delivered ||
        order.stage == FoodStage.receipt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacementNamed(AppRoutes.foodReceiptName);
      });
    }

    return FixtureGate(
      loading: const Center(child: CircularProgressIndicator()),
      builder: (context, bundle) => _TrackingBody(order: order, bundle: bundle),
    );
  }
}

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({required this.order, required this.bundle});

  final FoodOrder order;
  final FixtureBundle bundle;

  static const List<(FoodStage, String, IconData)> _steps = [
    (
      FoodStage.matchingCourier,
      'Matching a demo courier',
      Icons.search_rounded,
    ),
    (
      FoodStage.preparing,
      'Preparing your demo order',
      Icons.soup_kitchen_rounded,
    ),
    (FoodStage.onTheWay, 'Courier on the way', Icons.delivery_dining_rounded),
    (FoodStage.delivered, 'Delivered', Icons.check_rounded),
  ];

  static const Map<FoodStage, int> _stageRank = {
    FoodStage.matchingCourier: 0,
    FoodStage.preparing: 1,
    FoodStage.onTheWay: 2,
    FoodStage.delivered: 3,
    FoodStage.receipt: 3,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = _stageRank[order.stage] ?? 0;
    final courier = order.courierId == null
        ? null
        : bundle.driver(order.courierId!);

    // A deterministic demo route from the restaurant area to the home fixture.
    final home = bundle.defaultPickup.point;
    final origin = MapPoint(
      x: (home.x + 0.22).clamp(0.0, 1.0),
      y: (home.y - 0.18).clamp(0.0, 1.0),
    );

    return AppPage(
      title: 'Your demo order',
      subtitle: order.restaurantName ?? 'Demo restaurant',
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      footer: order.stage.isCancellable
          ? TonalButton(
              label: 'Cancel demo order',
              icon: Icons.close_rounded,
              onPressed: () => _confirmCancel(context, ref),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xs),
          SchematicMap(
            height: 200,
            origin: origin,
            destination: home,
            route: [origin, home],
            marker: MapPoint.lerp(origin, home, order.progress),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, step) in _steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          index <= rank
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: index <= rank
                              ? AppColors.success
                              : AppColors.neutralGray,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(step.$3, size: 15, color: AppColors.neutralGray),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            step.$2,
                            style: AppTypography.bodyMuted.copyWith(
                              color: index <= rank
                                  ? AppColors.deepNavy
                                  : AppColors.neutralGray,
                            ),
                          ),
                        ),
                        Text(
                          index <= rank ? 'Done' : 'Pending',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (courier != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              semanticLabel: 'Demo courier ${courier.displayName}',
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.tile,
                    child: Image.asset(
                      ImageAssets.resolve(courier.avatarAsset),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 48,
                        height: 48,
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
                        Text(
                          courier.displayName,
                          style: AppTypography.itemTitle,
                        ),
                        Text(
                          'Demo courier · ${courier.rating} ★',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'Courier progress is a local simulation. No live tracking or '
                'GPS is used.',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this demo order?'),
        content: const Text(
          'The simulated order will stop. Any demo wallet amount is returned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(foodProvider.notifier).cancel();
    context.goNamed(AppRoutes.homeName);
  }
}
