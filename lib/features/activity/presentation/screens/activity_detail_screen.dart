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
import '../../../../domain/entities/activity_record.dart';
import '../../application/activity_controller.dart';

/// Detail view for a single simulated journey.
///
/// Loads the record from the activity provider by id, so a stale or unknown id
/// shows a recoverable not-found state instead of an empty screen.
class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({required this.activityId, super.key});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(activityRecordProvider(activityId));

    if (record == null) {
      return AppPage(
        title: 'Journey details',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'This demo journey is no longer in the current session. '
                  'Activity history is held in memory only.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Back to activity',
              icon: Icons.receipt_long_rounded,
              onPressed: () => context.goNamed(AppRoutes.activityName),
            ),
          ],
        ),
      );
    }

    final completed = record.status == ActivityStatus.completed;

    return AppPage(
      title: 'Journey details',
      subtitle: record.kind.label,
      leading: const AppBackButton(),
      footer: PrimaryButton(
        label: 'Back to activity',
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.goNamed(AppRoutes.activityName),
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
                    StatusPill(
                      label: record.status.label,
                      tone: completed ? PillTone.success : PillTone.neutral,
                    ),
                    if (record.rating != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${record.rating} / 5',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(record.title, style: AppTypography.section),
                const SizedBox(height: AppSpacing.xxs),
                Text(record.subtitle, style: AppTypography.bodyMuted),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: '${record.kind.label} summary'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                DetailRow(label: 'Type', value: record.kind.label),
                DetailRow(
                  label: 'Settled amount',
                  value: Currency.format(record.amount),
                  emphasize: true,
                ),
                DetailRow(
                  label: 'Payment',
                  value: switch (record.paymentMethod) {
                    null => 'Not applicable',
                    'wallet' => 'Demo wallet',
                    'cash' => 'Cash',
                    _ => record.paymentMethod!,
                  },
                ),
                DetailRow(
                  label: 'Simulated at',
                  value: _formatTimestamp(record.createdAt),
                ),
                DetailRow(label: 'Journey id', value: record.journeyId),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'Every value on this screen comes from the local simulation. '
                'No real transaction occurred.',
          ),
        ],
      ),
    );
  }

  /// Formats a timestamp without `intl`, keeping the app dependency-light.
  static String _formatTimestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
