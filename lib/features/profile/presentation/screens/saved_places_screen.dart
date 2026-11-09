import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../application/profile_controller.dart';

/// Lets the user toggle which bundled demo places are saved.
class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  static const Map<String, IconData> _categoryIcons = {
    'saved': Icons.home_rounded,
    'education': Icons.school_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'transit': Icons.train_rounded,
    'leisure': Icons.park_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteIdsProvider);

    return AppPage(
      title: 'Saved places',
      subtitle: 'Choose which demo locations appear first',
      leading: const AppBackButton(),
      body: FixtureGate(
        loading: const Center(child: CircularProgressIndicator()),
        builder: (context, bundle) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'These are the bundled demo locations. Saving one only '
                  'changes the order shown in destination search.',
            ),
            const SizedBox(height: AppSpacing.md),
            for (final location in bundle.locations) ...[
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: SelectionRow(
                  title: location.name,
                  subtitle: location.addressLabel,
                  leading: IconWell(
                    icon:
                        _categoryIcons[location.category] ??
                        Icons.place_rounded,
                  ),
                  selected: favorites.contains(location.id),
                  semanticLabel:
                      '${location.name}, '
                      '${favorites.contains(location.id) ? 'saved' : 'not saved'}',
                  trailing: favorites.contains(location.id)
                      ? const Icon(
                          Icons.bookmark_rounded,
                          size: 20,
                          color: AppColors.primaryIndigo,
                        )
                      : const Icon(
                          Icons.bookmark_border_rounded,
                          size: 20,
                          color: AppColors.neutralGray,
                        ),
                  onTap: () => ref
                      .read(profileProvider.notifier)
                      .toggleFavorite(location.id),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${favorites.length} of ${bundle.locations.length} demo places '
              'saved',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Use a saved place for a demo ride',
              icon: Icons.search_rounded,
              onPressed: () =>
                  context.pushNamed(AppRoutes.destinationSearchName),
            ),
          ],
        ),
      ),
    );
  }
}
