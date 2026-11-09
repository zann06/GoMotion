import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../activity/application/activity_controller.dart';
import '../../../profile/application/profile_controller.dart';
import '../../application/simulation_reset.dart';

/// Demo settings: motion preference, simulation state, and reset.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset the demo simulation?'),
        content: const Text(
          'This clears all simulated journeys, activity history, unlocked '
          'rewards, and preference changes, and restores the fictional wallet '
          'to its starting balance. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset simulation'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(simulationResetProvider).run();
    if (!context.mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text('Demo simulation reset to its starting state.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.goNamed(AppRoutes.homeName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    final inAppMotion = ref.watch(inAppReduceMotionProvider);
    final systemMotion = ref.watch(systemReduceMotionProvider).enabled;
    final user = ref.watch(profileProvider);
    final activityCount = ref.watch(activityProvider).length;

    return AppPage(
      title: 'Settings',
      subtitle: 'Demo simulation preferences',
      leading: const AppBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Motion'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: inAppMotion,
                  onChanged: (value) =>
                      ref.read(inAppReduceMotionProvider.notifier).set(value),
                  title: const Text(
                    'Reduce motion',
                    style: AppTypography.itemTitle,
                  ),
                  subtitle: const Text(
                    'Turns off decorative animation throughout the demo.',
                    style: AppTypography.caption,
                  ),
                ),
                const Divider(height: 1, color: AppColors.lightBorder),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      size: 16,
                      color: AppColors.neutralGray,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        systemMotion
                            ? 'Your device already requests reduced motion.'
                            : 'Your device does not request reduced motion.',
                        style: AppTypography.caption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    motion.enabled
                        ? 'Effective setting: reduced motion on'
                        : 'Effective setting: full motion',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Simulation data'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Demo wallet',
                  value: Currency.format(user.demoWalletBalance),
                ),
                DetailRow(label: 'Demo points', value: '${user.rewardPoints}'),
                DetailRow(label: 'Activity records', value: '$activityCount'),
                DetailRow(
                  label: 'Saved demo places',
                  value: '${user.favoriteLocationIds.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppNotice(
            message:
                'Simulated activity is held in memory for this session only. '
                'Closing the app also restores the demo baseline.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Reset'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset everything to the fictional starting state. Use this '
                  'to replay the demo journeys from the beginning.',
                  style: AppTypography.bodyMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  label: 'Reset demo simulation',
                  icon: Icons.restart_alt_rounded,
                  onPressed: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TonalButton(
            label: 'About GoMotion',
            icon: Icons.info_outline_rounded,
            onPressed: () => context.pushNamed(AppRoutes.aboutName),
          ),
        ],
      ),
    );
  }
}
