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
import '../../application/food_controller.dart';

/// The GoFood demo receipt.
class FoodReceiptScreen extends ConsumerWidget {
  const FoodReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(foodProvider).order;

    if (order == null) {
      return AppPage(
        title: 'Demo receipt',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'This demo receipt is no longer available in the current '
                  'session. Completed orders remain listed in Activity.',
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
      subtitle: order.restaurantName ?? 'Demo restaurant',
      footer: PrimaryButton(
        label: 'Back to home',
        icon: Icons.home_rounded,
        onPressed: () {
          ref.read(foodProvider.notifier).reset();
          context.goNamed(AppRoutes.homeName);
        },
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
                          Text(
                            'Demo order delivered',
                            style: AppTypography.section,
                          ),
                          Text(
                            'Completed locally in this session',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final line in order.lines)
                  DetailRow(
                    label: '${line.quantity}× ${line.name}',
                    value: Currency.format(line.subtotal),
                  ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Demo delivery fee',
                  value: Currency.format(order.deliveryFee),
                ),
                DetailRow(
                  label: 'Total',
                  value: Currency.format(order.total),
                  emphasize: true,
                ),
                const DetailRow(
                  label: 'Demo points earned',
                  value: '+${AppInfo.demoPointsPerJourney} ${DemoCopy.points}',
                ),
                DetailRow(
                  label: 'Payment',
                  value: order.paymentMethod == FoodPayment.demoWallet
                      ? 'Demo wallet'
                      : 'Cash on delivery',
                ),
                DetailRow(label: 'Order id', value: order.id),
                const SizedBox(height: AppSpacing.xs),
                const Text(DemoCopy.transaction, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'This receipt is a fictional demo record. No real restaurant, '
                'courier, or payment provider was involved.',
          ),
        ],
      ),
    );
  }
}
