import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../application/food_controller.dart';

/// The GoFood browse screen: search, promo, categories, and popular kitchens.
///
/// Everything is filtered from the bundled fixture in memory. There is no
/// restaurant API, geolocation, or remote image: the cards are local
/// illustrations and the distances are authored demo values.
class FoodBrowseScreen extends ConsumerStatefulWidget {
  const FoodBrowseScreen({super.key});

  @override
  ConsumerState<FoodBrowseScreen> createState() => _FoodBrowseScreenState();
}

class _FoodBrowseScreenState extends ConsumerState<FoodBrowseScreen> {
  final TextEditingController _search = TextEditingController();
  final GlobalKey _restaurantSection = GlobalKey();

  String? _category;
  String _query = '';
  bool _showAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      // A search is already a focused result list, so skip the carousel.
      if (value.trim().isNotEmpty) _showAll = true;
    });
  }

  void _clearSearch() {
    _search.clear();
    setState(() {
      _query = '';
      _showAll = false;
    });
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _category = value;
      _showAll = false;
    });
  }

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = null;
      _showAll = false;
    });
  }

  /// Expands the full list and brings it into view.
  ///
  /// The board's "Order now" call to action lands on the restaurant list
  /// instead of starting an order on the user's behalf: the next step is still
  /// choosing a fictional kitchen.
  void _browseRestaurants() {
    setState(() => _showAll = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _restaurantSection.currentContext;
      if (target == null) return;
      final motion = ref.read(reduceMotionProvider);
      Scrollable.ensureVisible(
        target,
        alignment: 0.05,
        duration: motion.resolve(const Duration(milliseconds: 320)),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(foodProvider).order?.itemCount ?? 0;
    final motion = ref.watch(reduceMotionProvider);

    return AppPage(
      title: 'GoFood',
      subtitle: 'Order from fictional demo restaurants',
      actions: [_CartButton(count: cartCount)],
      body: FixtureGate(
        loading: const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: AppSkeletonList(itemCount: 3, itemHeight: 120),
        ),
        builder: (context, bundle) {
          final visible = filterRestaurants(
            bundle.restaurants,
            category: _category,
            query: _query,
          );
          final popular = [
            for (final restaurant in visible)
              if (restaurant.featured) restaurant,
          ];
          final isSearching = _query.trim().isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchField(
                controller: _search,
                onChanged: _onQueryChanged,
                onClear: _clearSearch,
              ),
              const SizedBox(height: AppSpacing.md),
              _PromoBanner(onBrowse: _browseRestaurants),
              const SizedBox(height: AppSpacing.md),
              _CategorySelector(
                selected: _category,
                onSelected: _onCategoryChanged,
                duration: motion.resolve(AppDuration.value),
              ),
              const SizedBox(height: AppSpacing.md),
              _RestaurantSection(
                key: _restaurantSection,
                visible: visible,
                popular: popular,
                isSearching: isSearching,
                showAll: _showAll,
                onToggleAll: () => setState(() => _showAll = !_showAll),
                onReset: _resetFilters,
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppNotice(
                message:
                    'Restaurants, dishes, prices, and distances are fictional '
                    'demo data. No real kitchen receives this order.',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A white search field sized like the reference's restaurant search.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search demo restaurants',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: 'Search restaurants...',
          hintStyle: AppTypography.bodyMuted,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.neutralGray,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  tooltip: 'Clear demo search',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.neutralGray,
                  ),
                ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.button,
            borderSide: BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.button,
            borderSide: BorderSide(color: AppColors.primaryIndigo, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// The fictional food promotion: a local illustration and one working action.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.hero,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'DEMO', tone: PillTone.onGradient),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Delicious food,\ndelivered fast',
                  style: AppTypography.section.copyWith(
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Fictional kitchens, bundled offline.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  button: true,
                  label: 'Browse all demo restaurants',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.white,
                    borderRadius: AppRadius.chip,
                    child: InkWell(
                      borderRadius: AppRadius.chip,
                      onTap: onBrowse,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Order now',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryIndigo,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primaryIndigo,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The dish yields width before the call to action truncates, so the
          // banner still fits at accessibility text scales.
          Flexible(
            child: ClipRRect(
              borderRadius: AppRadius.card,
              child: Image.asset(
                ImageAssets.resolve('salmon_bowl.png'),
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 104,
                  height: 104,
                  color: AppColors.white.withValues(alpha: 0.18),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All / Asian / Western / Local / Dessert, fixed to the reference board.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onSelected,
    required this.duration,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final values = <String?>[null, ...foodCategories];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, value) in values.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _CategoryTile(
              label: value ?? 'All',
              icon: _iconFor(value),
              selected: selected == value,
              duration: duration,
              onTap: () => onSelected(value),
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconFor(String? category) => switch (category) {
    null => Icons.grid_view_rounded,
    'Asian' => Icons.ramen_dining_rounded,
    'Western' => Icons.lunch_dining_rounded,
    'Local' => Icons.rice_bowl_rounded,
    'Dessert' => Icons.cake_rounded,
    _ => Icons.restaurant_rounded,
  };
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label == 'All' ? 'All demo categories' : '$label demo category',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            children: [
              AnimatedContainer(
                duration: duration,
                curve: Curves.easeOut,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryIndigo : AppColors.white,
                  borderRadius: AppRadius.card,
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryIndigo
                        : AppColors.lightBorder,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.white : AppColors.primaryIndigo,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: selected
                      ? AppColors.primaryIndigo
                      : AppColors.deepNavy,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The popular carousel, or the full list once "See all" is tapped.
class _RestaurantSection extends StatelessWidget {
  const _RestaurantSection({
    required this.visible,
    required this.popular,
    required this.isSearching,
    required this.showAll,
    required this.onToggleAll,
    required this.onReset,
    super.key,
  });

  final List<Restaurant> visible;
  final List<Restaurant> popular;
  final bool isSearching;
  final bool showAll;
  final VoidCallback onToggleAll;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (visible.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: isSearching
            ? 'No demo restaurants found'
            : 'No demo kitchens here',
        message: isSearching
            ? 'Try another restaurant name, or reset the demo filters.'
            : 'This category has no bundled restaurants yet. Reset the demo '
                  'filters to see every kitchen.',
        actionLabel: 'Reset filters',
        onAction: onReset,
        mascot: MascotVariant.error,
      );
    }

    final expanded = showAll || isSearching;
    final title = isSearching
        ? 'Search results'
        : (showAll ? 'All demo restaurants' : 'Popular Restaurants');
    final subtitle = isSearching
        ? '${visible.length} fictional '
              '${visible.length == 1 ? 'kitchen' : 'kitchens'} match'
        : (showAll
              ? '${visible.length} bundled demo '
                    '${visible.length == 1 ? 'kitchen' : 'kitchens'}'
              : 'Fictional kitchens near your demo location');
    final carousel = popular.isEmpty ? visible : popular;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          action: (!isSearching && visible.length > 1)
              ? TextButton(
                  onPressed: onToggleAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(showAll ? 'Show less' : 'See all'),
                      const SizedBox(width: 2),
                      Icon(
                        showAll
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                      ),
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (expanded)
          for (final restaurant in visible) ...[
            _RestaurantRow(restaurant: restaurant),
            const SizedBox(height: AppSpacing.sm),
          ]
        else
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: carousel.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _RestaurantCard(restaurant: carousel[index]),
            ),
          ),
      ],
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _open(context, restaurant),
        semanticLabel: _semantics(restaurant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              child: _RestaurantImage(
                restaurant: restaurant,
                height: 104,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTypography.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${restaurant.rating}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('·', style: AppTypography.caption),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${restaurant.distanceKm.toStringAsFixed(1)} km',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.category} · ${restaurant.etaLabel}',
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  const _RestaurantRow({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _open(context, restaurant),
      semanticLabel: _semantics(restaurant),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.tile,
            child: _RestaurantImage(
              restaurant: restaurant,
              height: 64,
              width: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  style: AppTypography.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${restaurant.rating} · '
                  '${restaurant.distanceKm.toStringAsFixed(1)} km · '
                  '${restaurant.etaLabel}',
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${restaurant.category} · Fictional demo kitchen',
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.restaurant,
    required this.height,
    required this.fit,
    this.width,
  });

  final Restaurant restaurant;
  final double height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImageAssets.resolve(restaurant.imageAsset),
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (context, error, stack) => Container(
        height: height,
        width: width ?? double.infinity,
        color: AppColors.indigoTint,
        child: const Icon(
          Icons.restaurant_rounded,
          color: AppColors.primaryIndigo,
          size: 28,
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: count == 0
          ? 'Open demo cart, empty'
          : 'Open demo cart, $count items',
      excludeSemantics: true,
      child: IconButton(
        tooltip: 'Demo cart',
        onPressed: () => context.pushNamed(AppRoutes.foodCartName),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 24),
            if (count > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryIndigo,
                    borderRadius: AppRadius.chip,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _open(BuildContext context, Restaurant restaurant) {
  context.pushNamed(
    AppRoutes.foodRestaurantName,
    pathParameters: {'restaurantId': restaurant.id},
  );
}

String _semantics(Restaurant restaurant) =>
    '${restaurant.name}, ${restaurant.category}, rated ${restaurant.rating}, '
    '${restaurant.distanceKm.toStringAsFixed(1)} kilometres away, delivery '
    '${restaurant.etaLabel}';
