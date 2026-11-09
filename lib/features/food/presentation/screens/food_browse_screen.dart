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
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../application/food_controller.dart';

/// The GoFood restaurant browse screen with a local category filter.
class FoodBrowseScreen extends ConsumerStatefulWidget {
  const FoodBrowseScreen({super.key});

  @override
  ConsumerState<FoodBrowseScreen> createState() => _FoodBrowseScreenState();
}

class _FoodBrowseScreenState extends ConsumerState<FoodBrowseScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(foodProvider).order?.itemCount ?? 0;

    return AppPage(
      title: 'GoFood',
      subtitle: 'Order from fictional demo restaurants',
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      actions: [
        if (cartCount > 0)
          Semantics(
            button: true,
            label: 'View demo cart with $cartCount items',
            child: TextButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.foodCartName),
              icon: const Icon(Icons.shopping_bag_rounded, size: 18),
              label: Text('Cart ($cartCount)'),
            ),
          ),
      ],
      body: FixtureGate(
        loading: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: AppSkeletonList(itemCount: 3, itemHeight: 120),
        ),
        builder: (context, bundle) => _BrowseBody(
          bundle: bundle,
          category: _category,
          onCategoryChanged: (value) => setState(() => _category = value),
        ),
      ),
    );
  }
}

class _BrowseBody extends ConsumerWidget {
  const _BrowseBody({
    required this.bundle,
    required this.category,
    required this.onCategoryChanged,
  });

  final FixtureBundle bundle;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = <String>{for (final r in bundle.restaurants) r.category};
    final visible = category == null
        ? bundle.restaurants
        : [
            for (final r in bundle.restaurants)
              if (r.category == category) r,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppNotice(
          message:
              'Every restaurant, dish, and price below is fictional demo data '
              'bundled with the app. No real delivery is arranged.',
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                label: 'All',
                selected: category == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final value in categories) ...[
                const SizedBox(width: AppSpacing.xs),
                _CategoryChip(
                  label: value,
                  selected: category == value,
                  onTap: () => onCategoryChanged(value),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          AppEmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'No demo restaurants here',
            message: 'Try a different filter to see the bundled restaurants.',
            actionLabel: 'Show all',
            onAction: () => onCategoryChanged(null),
          )
        else
          for (final restaurant in visible) ...[
            _RestaurantCard(restaurant: restaurant),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label category filter',
      child: Material(
        color: selected ? AppColors.primaryIndigo : AppColors.white,
        borderRadius: AppRadius.chip,
        child: InkWell(
          borderRadius: AppRadius.chip,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? AppColors.white : AppColors.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.pushNamed(
        AppRoutes.foodRestaurantName,
        pathParameters: {'restaurantId': restaurant.id},
      ),
      semanticLabel:
          '${restaurant.name}, ${restaurant.category}, rated '
          '${restaurant.rating}, delivery ${restaurant.etaLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            child: Image.asset(
              ImageAssets.resolve(restaurant.imageAsset),
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 120,
                color: AppColors.indigoTint,
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primaryIndigo,
                  size: 32,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        style: AppTypography.itemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (restaurant.featured)
                      const StatusPill(label: 'Featured'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text('${restaurant.rating}', style: AppTypography.caption),
                    const SizedBox(width: AppSpacing.xs),
                    const Text('·', style: AppTypography.caption),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${restaurant.category} · ${restaurant.etaLabel}',
                        style: AppTypography.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
