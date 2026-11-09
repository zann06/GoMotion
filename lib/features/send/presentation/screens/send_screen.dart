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
import '../../application/send_controller.dart';

/// The GoSend sender/recipient/package form.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _senderName = TextEditingController();
  final _senderAddress = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientAddress = TextEditingController();

  String? _error;

  @override
  void initState() {
    super.initState();
    // Seed the form from any existing draft so Back preserves input, per the
    // routing specification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final parcel = ref.read(sendProvider).parcel;
      if (parcel == null) {
        ref.read(sendProvider.notifier).startDraft();
        return;
      }
      _senderName.text = parcel.senderName;
      _senderAddress.text = parcel.senderAddress;
      _recipientName.text = parcel.recipientName;
      _recipientAddress.text = parcel.recipientAddress;
    });
  }

  @override
  void dispose() {
    _senderName.dispose();
    _senderAddress.dispose();
    _recipientName.dispose();
    _recipientAddress.dispose();
    super.dispose();
  }

  void _submit() {
    final notifier = ref.read(sendProvider.notifier);
    notifier.updateDraft(
      senderName: _senderName.text,
      senderAddress: _senderAddress.text,
      recipientName: _recipientName.text,
      recipientAddress: _recipientAddress.text,
    );

    final failure = notifier.requestQuote();
    if (failure != null) {
      setState(() => _error = failure.message);
      return;
    }

    setState(() => _error = null);
    context.pushNamed(AppRoutes.sendReviewName);
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(sendProvider).parcel;
    final selected = parcel?.category;

    return AppPage(
      title: 'GoSend',
      subtitle: 'Send a fictional parcel in this demo',
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Get demo quote',
            icon: Icons.receipt_long_rounded,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Nothing is dispatched — this is a local simulation',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppNotice(
            message:
                'All names and addresses you enter stay on this device and are '
                'never transmitted. Use fictional details.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (_error != null) ...[
            AppNotice(tone: NoticeTone.error, message: _error!),
            const SizedBox(height: AppSpacing.md),
          ],
          const SectionHeader(title: 'Sender'),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            label: 'Sender name',
            hint: 'e.g. Demo Sender',
            controller: _senderName,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Pickup address',
            hint: 'Fictional pickup address',
            controller: _senderAddress,
            prefixIcon: Icons.trip_origin_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Recipient'),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            label: 'Recipient name',
            hint: 'e.g. Demo Recipient',
            controller: _recipientName,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Delivery address',
            hint: 'Fictional delivery address',
            controller: _recipientAddress,
            prefixIcon: Icons.place_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Package category',
            subtitle: 'Affects the simulated fee',
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final category in PackageCategory.values)
                  SelectionRow(
                    title: category.label,
                    subtitle: category.surcharge == 0
                        ? 'No demo surcharge'
                        : '+ ${Currency.format(category.surcharge)} demo fee',
                    selected: selected == category,
                    leading: IconWell(
                      icon: switch (category) {
                        PackageCategory.document => Icons.description_rounded,
                        PackageCategory.smallParcel =>
                          Icons.inventory_2_rounded,
                        PackageCategory.largeParcel =>
                          Icons.local_shipping_rounded,
                      },
                    ),
                    trailing: selected == category
                        ? const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.primaryIndigo,
                          )
                        : null,
                    onTap: () => ref
                        .read(sendProvider.notifier)
                        .updateDraft(category: category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
