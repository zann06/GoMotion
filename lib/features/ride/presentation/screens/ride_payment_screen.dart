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
import '../../../../domain/entities/ride.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../ride/application/ride_controller.dart';

/// Payment method selection and local settlement.
///
/// Both options are fictional. The demo wallet checks the local balance; cash
/// simply records the method. A second payment attempt is rejected by the
/// controller, so this screen never double-charges.
class RidePaymentScreen extends ConsumerStatefulWidget {
  const RidePaymentScreen({super.key});

  @override
  ConsumerState<RidePaymentScreen> createState() => _RidePaymentScreenState();
}

class _RidePaymentScreenState extends ConsumerState<RidePaymentScreen> {
  String _method = PaymentMethod.cash;
  bool _submitting = false;

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final failure = ref.read(rideProvider.notifier).pay(_method);
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

    context.pushReplacementNamed(AppRoutes.rideReceiptName);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideProvider);
    final ride = state.ride;
    final balance = ref.watch(walletBalanceProvider);

    if (ride == null || !ride.stage.isPayable) {
      final alreadyPaid =
          ride != null &&
          (ride.stage == RideStage.paid || ride.stage == RideStage.rated);

      if (alreadyPaid) {
        return AppPage(
          title: 'Payment',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppNotice(
                tone: NoticeTone.success,
                message: 'This demo ride is already paid.',
              ),
              const SizedBox(height: AppSpacing.md),
              TonalButton(
                label: 'View demo receipt',
                icon: Icons.receipt_long_rounded,
                onPressed: () =>
                    context.pushReplacementNamed(AppRoutes.rideReceiptName),
              ),
            ],
          ),
        );
      }

      return AppPage(
        title: 'Payment',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message: 'There is no completed demo ride to pay for.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Back to home',
              icon: Icons.home_rounded,
              onPressed: () => context.goNamed(AppRoutes.homeName),
            ),
          ],
        ),
      );
    }

    final total = ride.total;
    final walletCovers = balance >= total;

    return AppPage(
      title: 'Pay for your demo ride',
      subtitle: 'Choose a fictional payment method',
      // Return to the dashboard rather than popping into a stale vehicle
      // selection left behind by the push-replacement chain.
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Confirm demo payment',
            icon: Icons.lock_outline_rounded,
            loading: _submitting,
            onPressed: _pay,
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            DemoCopy.transaction,
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
                Text(
                  '${ride.pickup.name} → ${ride.destination.name}',
                  style: AppTypography.itemTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                DetailRow(
                  label: 'Subtotal',
                  value: Currency.format(ride.fare?.subtotal ?? 0),
                ),
                if ((ride.fare?.discount ?? 0) > 0)
                  DetailRow(
                    label: 'Promo discount',
                    value: '− ${Currency.format(ride.fare!.discount)}',
                    valueColor: AppColors.success,
                  ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'To pay',
                  value: Currency.format(total),
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(DemoCopy.fare, style: AppTypography.caption),
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
                  title: 'Cash',
                  subtitle: 'Pay the fictional driver directly',
                  selected: _method == PaymentMethod.cash,
                  onTap: () => setState(() => _method = PaymentMethod.cash),
                  leading: const IconWell(icon: Icons.payments_rounded),
                  trailing: _method == PaymentMethod.cash
                      ? const _SelectedCheck()
                      : null,
                ),
                SelectionRow(
                  title: 'Demo wallet',
                  subtitle:
                      'Fictional balance ${Currency.format(balance)}'
                      '${walletCovers ? '' : ' — not enough for this fare'}',
                  selected: _method == PaymentMethod.demoWallet,
                  onTap: () =>
                      setState(() => _method = PaymentMethod.demoWallet),
                  leading: const IconWell(
                    icon: Icons.account_balance_wallet_rounded,
                    background: AppColors.blueTint,
                    foreground: AppColors.electricBlue,
                  ),
                  trailing: _method == PaymentMethod.demoWallet
                      ? const _SelectedCheck()
                      : null,
                ),
              ],
            ),
          ),
          if (!walletCovers) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppNotice(
              tone: NoticeTone.warning,
              message:
                  'Your fictional demo wallet balance is below this fare. '
                  'Choose cash, or reset the simulation to restore the balance.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'No real payment is processed. No card, bank, or wallet '
                'provider is contacted.',
          ),
        ],
      ),
    );
  }
}

class _SelectedCheck extends StatelessWidget {
  const _SelectedCheck();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.check_circle_rounded,
      size: 20,
      color: AppColors.primaryIndigo,
    );
  }
}
