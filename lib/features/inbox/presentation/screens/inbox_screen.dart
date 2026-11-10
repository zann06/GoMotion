import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../domain/entities/inbox_message.dart';
import '../../application/inbox_controller.dart';

/// The simulated inbox.
///
/// Every row comes from `notifications.json`. There is no push service, no
/// server, and no real sender: tapping a row only marks it read and, when the
/// fixture provides one, opens another local screen.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxProvider);
    final controller = ref.read(inboxProvider.notifier);
    final unread = state.unreadCount;

    return AppPage(
      title: 'Inbox',
      subtitle: 'Simulated notifications from bundled demo data',
      actions: [
        if (unread > 0)
          TextButton(
            onPressed: controller.markAllRead,
            child: Text('Mark all read ($unread)'),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: state.filter == null,
                  onTap: () => controller.setFilter(null),
                ),
                for (final kind in InboxKind.values) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _FilterChip(
                    label: kind.label,
                    selected: state.filter == kind,
                    onTap: () => controller.setFilter(kind),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.isEmpty)
            const AppEmptyState(
              icon: Icons.mark_email_read_outlined,
              title: 'No demo messages',
              message:
                  'This inbox is seeded from the bundled fixture. When the '
                  'dataset carries messages they appear here.',
            )
          else if (state.visible.isEmpty)
            AppEmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'Nothing in this filter',
              message: 'Switch back to All to see every demo message.',
              actionLabel: 'Show all',
              onAction: () => controller.setFilter(null),
            )
          else
            for (final message in state.visible) ...[
              _MessageCard(
                message: message,
                onTap: () {
                  controller.markRead(message.id);
                  final route = message.actionRoute;
                  if (route != null && route.isNotEmpty) {
                    context.go(route);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          const SizedBox(height: AppSpacing.xs),
          const AppNotice(
            message:
                'These messages are fictional samples written for the demo. '
                'Nothing is fetched, pushed, or delivered, and no notification '
                'permission is requested.',
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
      label: '$label inbox filter',
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onTap});

  final InboxMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !message.read;
    final (icon, tint, foreground) = switch (message.kind) {
      InboxKind.order => (
        Icons.receipt_long_rounded,
        AppColors.indigoTint,
        AppColors.primaryIndigo,
      ),
      InboxKind.promo => (
        Icons.local_offer_rounded,
        AppColors.blueTint,
        AppColors.electricBlue,
      ),
      InboxKind.system => (
        Icons.info_outline_rounded,
        AppColors.indigoTint,
        AppColors.violet,
      ),
    };

    return AppCard(
      onTap: onTap,
      semanticLabel: unread
          ? '${message.title}, unread, ${message.kind.label}'
          : '${message.title}, read, ${message.kind.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: AppRadius.tile,
                ),
                child: Icon(icon, size: 20, color: foreground),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (unread) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryIndigo,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            message.title,
                            style: AppTypography.itemTitle.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: unread
                                  ? AppColors.deepNavy
                                  : AppColors.deepNavy.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${message.kind.label} · ${message.timeLabel}',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message.body, style: AppTypography.bodyMuted),
          if (message.hasAction) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  message.actionLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryIndigo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primaryIndigo,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
