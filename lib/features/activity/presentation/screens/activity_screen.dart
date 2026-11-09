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
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/empty_state_body.dart';
import '../../../../domain/entities/activity_record.dart';
import '../../application/activity_controller.dart';

/// The unified history of simulated journeys.
///
/// Shows only journeys the simulation actually produced; an empty ledger shows
/// an honest empty state with a route back into the demo flows.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  ActivityKind? _filter;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(activityFilterProvider(_filter));
    final all = ref.watch(activityProvider);

    return AppPage(
      title: 'Your activity',
      subtitle: 'A history of simulated journeys',
      body: all.isEmpty
          ? EmptyStateBody(
              icon: Icons.receipt_long_outlined,
              title: 'No demo journeys yet',
              message:
                  'Completed rides, food orders, and parcel deliveries appear '
                  'here once you finish a simulated journey.',
              actionLabel: 'Start a demo ride',
              onAction: () => context.goNamed(AppRoutes.destinationSearchName),
              mascot: MascotVariant.wave,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final kind in ActivityKind.values) ...[
                        const SizedBox(width: AppSpacing.xs),
                        _FilterChip(
                          label: kind.label,
                          selected: _filter == kind,
                          onTap: () => setState(() => _filter = kind),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (records.isEmpty)
                  AppEmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Nothing in this filter',
                    message:
                        'No ${_filter?.label.toLowerCase() ?? 'demo'} journeys '
                        'have been completed yet.',
                    actionLabel: 'Show all activity',
                    onAction: () => setState(() => _filter = null),
                    mascot: MascotVariant.wave,
                  )
                else
                  for (final record in records) ...[
                    _ActivityCard(record: record),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.sm),
                const AppNotice(
                  message:
                      'Activity is held in memory for this session only. '
                      'Restarting the app restores the demo baseline.',
                ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      label: '$label activity filter',
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.record});

  final ActivityRecord record;

  static const Map<ActivityKind, IconData> _icons = {
    ActivityKind.ride: Icons.directions_car_rounded,
    ActivityKind.food: Icons.restaurant_rounded,
    ActivityKind.send: Icons.inventory_2_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final completed = record.status == ActivityStatus.completed;

    return AppCard(
      onTap: () => context.pushNamed(
        AppRoutes.activityDetailName,
        pathParameters: {'activityId': record.journeyId},
      ),
      semanticLabel:
          '${record.kind.label}, ${record.title}, ${record.status.label}, '
          '${Currency.format(record.amount)}',
      child: Row(
        children: [
          IconWell(icon: _icons[record.kind] ?? Icons.receipt_long_rounded),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: AppTypography.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  record.subtitle,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    // Status is stated in text, never by colour alone.
                    StatusPill(
                      label: record.status.label,
                      tone: completed ? PillTone.success : PillTone.neutral,
                    ),
                    if (record.rating != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text('${record.rating}', style: AppTypography.caption),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Currency.format(record.amount), style: AppTypography.amount),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.neutralGray,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
