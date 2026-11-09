import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/empty_state_body.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/food_order.dart';
import '../../application/food_controller.dart';

/// The cart review screen with quantity controls and a delivery-fee breakdown.
class FoodCartScreen extends ConsumerWidget {
  const FoodCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(foodProvider).order;

    if (order == null || order.isEmpty) {
      return AppPage(
        title: 'Your demo cart',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EmptyStateBody(
              icon: Icons.shopping_bag_outlined,
              title: 'Your demo cart is empty',
              message:
                  'Add a dish from one of the bundled demo restaurants to '
                  'continue.',
              mascot: MascotVariant.food,
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

    return AppPage(
      title: 'Your demo cart',
      subtitle: order.restaurantName ?? 'Demo restaurant',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Continue to checkout',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              final failure = ref.read(foodProvider.notifier).beginCheckout();
              if (failure != null) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  SnackBar(
                    content: Text(failure.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              context.pushNamed(AppRoutes.foodCheckoutName);
            },
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Demo totals only — nothing is charged yet',
            style: AppTypography.caption,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in order.lines) ...[
            _CartLineCard(order: order, line: line),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Items (${order.itemCount})',
                  value: Currency.format(order.itemsTotal),
                ),
                DetailRow(
                  label: 'Demo delivery fee',
                  value: Currency.format(order.deliveryFee),
                ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Estimated total',
                  value: Currency.format(order.total),
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
          Row(
            children: [
              Expanded(
                child: TonalButton(
                  label: 'Add more items',
                  icon: Icons.add_rounded,
                  onPressed: order.restaurantId == null
                      ? null
                      : () => context.pushReplacementNamed(
                          AppRoutes.foodRestaurantName,
                          pathParameters: {'restaurantId': order.restaurantId!},
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () {
              ref.read(foodProvider.notifier).clearCart();
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(
                  content: Text('Demo cart cleared.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Clear demo cart'),
          ),
        ],
      ),
    );
  }
}

class _CartLineCard extends ConsumerWidget {
  const _CartLineCard({required this.order, required this.line});

  final FoodOrder order;
  final CartLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      semanticLabel:
          '${line.name}, ${Currency.format(line.unitPrice)} each, '
          'quantity ${line.quantity}',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(
                  '${Currency.format(line.unitPrice)} each',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  Currency.format(line.subtotal),
                  style: AppTypography.amount,
                ),
              ],
            ),
          ),
          QuantityStepper(
            quantity: line.quantity,
            itemName: line.name,
            onIncrement: () =>
                ref.read(foodProvider.notifier).incrementItem(line.itemId),
            onDecrement: () =>
                ref.read(foodProvider.notifier).removeItem(line.itemId),
          ),
        ],
      ),
    );
  }
}
