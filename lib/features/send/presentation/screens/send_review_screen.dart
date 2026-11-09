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
import '../../../../core/widgets/primary_button.dart';
import '../../../../domain/entities/parcel_delivery.dart';
import '../../../profile/application/profile_controller.dart';
import '../../application/send_controller.dart';

/// The GoSend quote review and confirmation screen.
class SendReviewScreen extends ConsumerStatefulWidget {
  const SendReviewScreen({super.key});

  @override
  ConsumerState<SendReviewScreen> createState() => _SendReviewScreenState();
}

class _SendReviewScreenState extends ConsumerState<SendReviewScreen> {
  String _method = SendPayment.demoWallet;
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final failure = ref
        .read(sendProvider.notifier)
        .confirm(paymentMethod: _method);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (failure != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(failure.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.pushReplacementNamed(AppRoutes.sendTrackingName);
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(sendProvider).parcel;
    final balance = ref.watch(walletBalanceProvider);

    if (parcel == null || parcel.stage == SendStage.draft) {
      return AppPage(
        title: 'Demo quote',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message: 'Enter the parcel details to get a demo quote first.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Back to parcel details',
              icon: Icons.edit_rounded,
              onPressed: () => context.pushReplacementNamed(AppRoutes.sendName),
            ),
          ],
        ),
      );
    }

    final walletCovers = balance >= parcel.total;

    return AppPage(
      title: 'Demo quote',
      subtitle: 'Review this fictional parcel before confirming',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Confirm demo parcel · ${Currency.format(parcel.total)}',
            icon: Icons.check_rounded,
            loading: _submitting,
            onPressed: _confirm,
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            DemoCopy.fee,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'Demo parcel'),
                const SizedBox(height: AppSpacing.sm),
                DetailRow(label: 'From', value: parcel.senderName),
                DetailRow(label: 'Pickup', value: parcel.senderAddress),
                DetailRow(label: 'To', value: parcel.recipientName),
                DetailRow(label: 'Delivery', value: parcel.recipientAddress),
                DetailRow(
                  label: 'Category',
                  value: parcel.category?.label ?? 'Document',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Fee estimate'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Base demo fee',
                  value: Currency.format(parcel.baseFee),
                ),
                DetailRow(
                  label:
                      'Distance (${parcel.distanceKm.toStringAsFixed(1)} km '
                      'simulated)',
                  value: Currency.format(
                    (parcel.perKmFee * parcel.distanceKm).round(),
                  ),
                ),
                if (parcel.surcharge > 0)
                  DetailRow(
                    label: '${parcel.category?.label ?? ''} surcharge',
                    value: Currency.format(parcel.surcharge),
                  ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Estimated total',
                  value: Currency.format(parcel.total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(DemoCopy.fee, style: AppTypography.caption),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Payment method'),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                SelectionRow(
                  title: 'Demo wallet',
                  subtitle:
                      'Fictional balance ${Currency.format(balance)}'
                      '${walletCovers ? '' : ' — not enough for this fee'}',
                  selected: _method == SendPayment.demoWallet,
                  leading: const IconWell(
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  onTap: () => setState(() => _method = SendPayment.demoWallet),
                ),
                SelectionRow(
                  title: 'Cash',
                  subtitle: 'Pay the fictional courier directly',
                  selected: _method == SendPayment.cash,
                  leading: const IconWell(
                    icon: Icons.payments_rounded,
                    background: AppColors.blueTint,
                    foreground: AppColors.electricBlue,
                  ),
                  onTap: () => setState(() => _method = SendPayment.cash),
                ),
              ],
            ),
          ),
          if (!walletCovers) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppNotice(
              tone: NoticeTone.warning,
              message:
                  'Your fictional demo wallet balance is below this fee. '
                  'Choose cash, or reset the simulation.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'No parcel is actually collected. Nothing leaves this device.',
          ),
        ],
      ),
    );
  }
}
