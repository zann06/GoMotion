import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../profile/application/profile_controller.dart';
import '../../application/rewards_controller.dart';

/// Demo rewards: unlock fictional badges with fictional points.
class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref,
    Reward reward,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Free rewards unlock immediately; paid ones ask for confirmation first.
    if (reward.pointsCost > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Unlock "${reward.title}"?'),
          content: Text(
            'This spends ${reward.pointsCost} of your fictional demo points. '
            'Demo points have no real value.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Unlock'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    final failure = ref.read(rewardsProvider.notifier).redeem(reward);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? '${reward.title} unlocked in this demo session.'
              : failure.message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(profileProvider).rewardPoints;
    final unlocked = ref.watch(rewardsProvider);
    final catalogue = ref.watch(rewardCatalogueProvider);

    return AppPage(
      title: 'Rewards',
      subtitle: 'Fictional demo points and badges',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 28,
                  color: AppColors.primaryIndigo,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Demo points', style: AppTypography.caption),
                      Text('$points', style: AppTypography.amount),
                    ],
                  ),
                ),
                StatusPill(
                  label: '${unlocked.length}/${catalogue.length} unlocked',
                  tone: PillTone.brand,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (catalogue.isEmpty)
            const AppNotice(
              message: 'The demo reward catalogue is still loading.',
            )
          else
            for (final reward in catalogue) ...[
              _RewardCard(
                reward: reward,
                unlocked: unlocked.contains(reward.id),
                affordable: points >= reward.pointsCost,
                onRedeem: () => _redeem(context, ref, reward),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.xs),
          const AppNotice(
            message:
                'Demo points and badges are fictional and stored only for this '
                'session. They cannot be exchanged for anything.',
          ),
          const SizedBox(height: AppSpacing.md),
          TonalButton(
            label: 'Complete a demo journey for more points',
            icon: Icons.directions_car_rounded,
            onPressed: () => context.goNamed(AppRoutes.destinationSearchName),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.unlocked,
    required this.affordable,
    required this.onRedeem,
  });

  final Reward reward;
  final bool unlocked;
  final bool affordable;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      semanticLabel:
          '${reward.title}, ${reward.description}, '
          '${unlocked ? 'unlocked' : '${reward.pointsCost} demo points'}',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.successTint : AppColors.indigoTint,
              borderRadius: AppRadius.tile,
            ),
            child: Icon(
              unlocked
                  ? Icons.workspace_premium_rounded
                  : Icons.lock_outline_rounded,
              size: 22,
              color: unlocked ? AppColors.success : AppColors.primaryIndigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppTypography.itemTitle),
                const SizedBox(height: 2),
                Text(
                  reward.description,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  unlocked
                      ? 'Unlocked in this demo session'
                      : reward.pointsCost == 0
                      ? 'Free demo reward'
                      : '${reward.pointsCost} demo points',
                  style: AppTypography.caption.copyWith(
                    color: unlocked ? AppColors.success : AppColors.neutralGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (unlocked)
            const StatusPill(label: 'Unlocked', tone: PillTone.success)
          else
            SizedBox(
              width: 96,
              child: PrimaryButton(
                label: 'Unlock',
                onPressed: affordable ? onRedeem : null,
                expand: false,
              ),
            ),
        ],
      ),
    );
  }
}
