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
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../application/food_controller.dart';

/// Restaurant detail with the menu and quantity controls.
class FoodRestaurantScreen extends ConsumerWidget {
  const FoodRestaurantScreen({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FixtureGate(
      loading: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AppSkeletonList(itemCount: 4, itemHeight: 96),
      ),
      builder: (context, bundle) {
        final restaurant = bundle.restaurant(restaurantId);
        if (restaurant == null) {
          return AppPage(
            title: 'Restaurant unavailable',
            leading: const AppBackButton(),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppNotice(
                  message:
                      'This demo restaurant is not part of the bundled '
                      'dataset.',
                ),
                const SizedBox(height: AppSpacing.md),
                TonalButton(
                  label: 'Back to restaurants',
                  onPressed: () => context.goNamed(AppRoutes.foodName),
                ),
              ],
            ),
          );
        }

        final items = bundle.menuFor(restaurant.id);
        return _RestaurantBody(restaurant: restaurant, items: items);
      },
    );
  }
}

class _RestaurantBody extends ConsumerWidget {
  const _RestaurantBody({required this.restaurant, required this.items});

  final Restaurant restaurant;
  final List<MenuItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(foodProvider).order;
    final itemCount = order?.restaurantId == restaurant.id
        ? order!.itemCount
        : 0;

    return AppPage(
      title: restaurant.name,
      subtitle:
          '${restaurant.category} · ${restaurant.rating} ★ · '
          '${restaurant.etaLabel}',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: itemCount == 0
                ? 'Add an item to continue'
                : 'View demo cart ($itemCount)',
            icon: Icons.shopping_bag_rounded,
            onPressed: itemCount == 0
                ? null
                : () => context.pushNamed(AppRoutes.foodCartName),
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Prices are fictional demo amounts',
            style: AppTypography.caption,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppRadius.card,
            child: Image.asset(
              ImageAssets.resolve(restaurant.imageAsset),
              height: 180,
              width: double.infinity,
              // Fitted, not cropped: the illustration is square and a cover fit
              // would slice the dish.
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Container(
                height: 180,
                color: AppColors.indigoTint,
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 40,
                  color: AppColors.primaryIndigo,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Menu'),
          const SizedBox(height: AppSpacing.xs),
          if (items.isEmpty)
            const AppNotice(
              message: 'This demo restaurant has no menu items bundled yet.',
            )
          else
            for (final item in items) ...[
              _MenuItemCard(
                item: item,
                quantity: order?.restaurantId == restaurant.id
                    ? (order?.quantityOf(item.id) ?? 0)
                    : 0,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'This menu is fictional demo content. No real restaurant is '
                'involved and no order is sent anywhere.',
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends ConsumerWidget {
  const _MenuItemCard({required this.item, required this.quantity});

  final MenuItem item;
  final int quantity;

  void _add(BuildContext context, WidgetRef ref) {
    final failure = ref.read(foodProvider.notifier).addItem(item);
    if (failure != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      semanticLabel:
          '${item.name}, ${Currency.format(item.price)}'
          '${quantity > 0 ? ', $quantity in cart' : ''}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.tile,
            child: Image.asset(
              ImageAssets.resolve(item.imageAsset),
              width: 64,
              height: 64,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Container(
                width: 64,
                height: 64,
                color: AppColors.indigoTint,
                child: const Icon(
                  Icons.restaurant_menu_rounded,
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
                Text(item.name, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(Currency.format(item.price), style: AppTypography.amount),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (quantity == 0)
            Semantics(
              button: true,
              label: 'Add ${item.name} to demo cart',
              child: IconButton.filled(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryIndigo,
                  minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                ),
              ),
            )
          else
            QuantityStepper(
              quantity: quantity,
              itemName: item.name,
              onIncrement: () => _add(context, ref),
              onDecrement: () =>
                  ref.read(foodProvider.notifier).removeItem(item.id),
            ),
        ],
      ),
    );
  }
}
