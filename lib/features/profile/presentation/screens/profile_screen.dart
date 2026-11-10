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
import '../../application/profile_controller.dart';

/// The fictional demo profile: wallet, points, saved places, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);

    return AppPage(
      title: 'Your profile',
      subtitle: 'A fictional demo account',
      body: FixtureGate(
        loading: const Center(child: CircularProgressIndicator()),
        builder: (context, bundle) {
          final favorites = [
            for (final id in user.favoriteLocationIds)
              if (bundle.location(id) != null) bundle.location(id)!,
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        ImageAssets.resolve(user.avatarAsset),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: 56,
                          height: 56,
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
                          Text(user.displayName, style: AppTypography.section),
                          const SizedBox(height: 2),
                          const Text(
                            'Demo account · fictional data',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Demo wallet',
                      value: Currency.format(user.demoWalletBalance),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Demo points',
                      value: '${user.rewardPoints}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Saved places'),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    if (favorites.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          'No saved demo places yet. Save a place to see it '
                          'here.',
                          style: AppTypography.caption,
                        ),
                      )
                    else
                      for (final location in favorites)
                        SelectionRow(
                          title: location.name,
                          subtitle: location.addressLabel,
                          leading: const IconWell(icon: Icons.bookmark_rounded),
                          trailing: TextButton(
                            onPressed: () => ref
                                .read(profileProvider.notifier)
                                .toggleFavorite(location.id),
                            child: const Text('Remove'),
                          ),
                        ),
                    const Divider(
                      height: AppSpacing.md,
                      color: AppColors.lightBorder,
                    ),
                    SelectionRow(
                      title: 'Manage saved places',
                      subtitle: 'Add or remove demo places',
                      leading: const IconWell(
                        icon: Icons.edit_location_alt_rounded,
                        background: AppColors.blueTint,
                        foreground: AppColors.electricBlue,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.neutralGray,
                      ),
                      onTap: () => context.pushNamed(AppRoutes.savedPlacesName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Demo rewards'),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: SelectionRow(
                  title: 'Rewards',
                  subtitle: 'Fictional badges for demo milestones',
                  leading: const IconWell(
                    icon: Icons.workspace_premium_rounded,
                    background: AppColors.blueTint,
                    foreground: AppColors.electricBlue,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.neutralGray,
                  ),
                  onTap: () => context.pushNamed(AppRoutes.rewardsName),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Demo settings'),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    SelectionRow(
                      title: 'Settings',
                      subtitle: 'Motion, simulation, and demo data preferences',
                      leading: const IconWell(icon: Icons.settings_rounded),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.neutralGray,
                      ),
                      onTap: () => context.pushNamed(AppRoutes.settingsName),
                    ),
                    SelectionRow(
                      title: 'About GoMotion',
                      subtitle: 'Offline simulation details',
                      leading: const IconWell(
                        icon: Icons.info_outline_rounded,
                        background: AppColors.blueTint,
                        foreground: AppColors.electricBlue,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.neutralGray,
                      ),
                      onTap: () => context.pushNamed(AppRoutes.aboutName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppNotice(
                message:
                    'Wallet balance, reward points, and saved places are '
                    'fictional demo values held in memory. No real account, '
                    'money, or personal data is involved.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticLabel: '$label, $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryIndigo),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.amount),
          ),
        ],
      ),
    );
  }
}
