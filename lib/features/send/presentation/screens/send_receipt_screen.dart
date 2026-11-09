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
import '../../application/send_controller.dart';

/// The GoSend demo receipt.
class SendReceiptScreen extends ConsumerWidget {
  const SendReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcel = ref.watch(sendProvider).parcel;

    if (parcel == null) {
      return AppPage(
        title: 'Demo receipt',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message:
                  'This demo receipt is no longer available in the current '
                  'session. Completed parcels remain listed in Activity.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Open activity',
              icon: Icons.receipt_long_rounded,
              onPressed: () => context.goNamed(AppRoutes.activityName),
            ),
          ],
        ),
      );
    }

    return AppPage(
      title: 'Demo receipt',
      subtitle: 'Fictional parcel delivery record',
      footer: PrimaryButton(
        label: 'Back to home',
        icon: Icons.home_rounded,
        onPressed: () {
          ref.read(sendProvider.notifier).reset();
          context.goNamed(AppRoutes.homeName);
        },
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.successTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Demo parcel delivered',
                            style: AppTypography.section,
                          ),
                          Text(
                            'Completed locally in this session',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DetailRow(label: 'From', value: parcel.senderName),
                DetailRow(label: 'Pickup', value: parcel.senderAddress),
                DetailRow(label: 'To', value: parcel.recipientName),
                DetailRow(label: 'Delivery', value: parcel.recipientAddress),
                DetailRow(
                  label: 'Category',
                  value: parcel.category?.label ?? 'Document',
                ),
                DetailRow(
                  label: 'Payment',
                  value: parcel.paymentMethod == SendPayment.demoWallet
                      ? 'Demo wallet'
                      : 'Cash',
                ),
                DetailRow(label: 'Parcel id', value: parcel.id),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Total',
                  value: Currency.format(parcel.total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(DemoCopy.transaction, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'This is a fictional demo record. No parcel was collected and '
                'no courier was dispatched.',
          ),
        ],
      ),
    );
  }
}
