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
import '../../../profile/application/profile_controller.dart';
import '../../application/food_controller.dart';

/// GoFood checkout: confirm the demo order and choose a payment method.
class FoodCheckoutScreen extends ConsumerStatefulWidget {
  const FoodCheckoutScreen({super.key});

  @override
  ConsumerState<FoodCheckoutScreen> createState() => _FoodCheckoutScreenState();
}

class _FoodCheckoutScreenState extends ConsumerState<FoodCheckoutScreen> {
  String _method = FoodPayment.demoWallet;
  bool _submitting = false;

  Future<void> _placeOrder() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final failure = ref
        .read(foodProvider.notifier)
        .placeOrder(paymentMethod: _method);

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

    context.pushReplacementNamed(AppRoutes.foodTrackingName);
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(foodProvider).order;
    final balance = ref.watch(walletBalanceProvider);

    if (order == null || order.isEmpty) {
      return AppPage(
        title: 'Checkout',
        leading: const AppBackButton(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(message: 'There is no demo cart to check out.'),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Browse demo restaurants',
              icon: Icons.restaurant_rounded,
              onPressed: () => context.goNamed(AppRoutes.foodName),
            ),
          ],
        ),
      );
    }

    final walletCovers = balance >= order.total;

    return AppPage(
      title: 'Checkout',
      subtitle: order.restaurantName ?? 'Demo restaurant',
      leading: const AppBackButton(),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Place demo order · ${Currency.format(order.total)}',
            icon: Icons.check_rounded,
            loading: _submitting,
            onPressed: _placeOrder,
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
                  '${order.itemCount} demo '
                  '${order.itemCount == 1 ? 'item' : 'items'}',
                  style: AppTypography.itemTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final line in order.lines)
                  DetailRow(
                    label: '${line.quantity}× ${line.name}',
                    value: Currency.format(line.subtotal),
                  ),
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.lightBorder,
                ),
                DetailRow(
                  label: 'Demo delivery fee',
                  value: Currency.format(order.deliveryFee),
                ),
                DetailRow(
                  label: 'Total',
                  value: Currency.format(order.total),
                  emphasize: true,
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
                      '${walletCovers ? '' : ' — not enough for this order'}',
                  selected: _method == FoodPayment.demoWallet,
                  onTap: () => setState(() => _method = FoodPayment.demoWallet),
                  leading: const IconWell(
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ),
                SelectionRow(
                  title: 'Cash on delivery',
                  subtitle: 'Pay the fictional courier directly',
                  selected: _method == FoodPayment.cash,
                  onTap: () => setState(() => _method = FoodPayment.cash),
                  leading: const IconWell(
                    icon: Icons.payments_rounded,
                    background: AppColors.blueTint,
                    foreground: AppColors.electricBlue,
                  ),
                ),
              ],
            ),
          ),
          if (!walletCovers) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppNotice(
              tone: NoticeTone.warning,
              message:
                  'Your fictional demo wallet balance is below this order '
                  'total. Choose cash on delivery, or reset the simulation.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'No real order is placed and no payment is processed. The '
                'courier simulation runs entirely on this device.',
          ),
        ],
      ),
    );
  }
}
