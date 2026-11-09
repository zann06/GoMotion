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
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/schematic_map.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/entities/parcel_delivery.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../application/send_controller.dart';

/// Courier matching and parcel transit tracking.
class SendTrackingScreen extends ConsumerWidget {
  const SendTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcel = ref.watch(sendProvider).parcel;

    if (parcel == null) {
      return AppPage(
        title: 'Demo parcel',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppNotice(
              message: 'There is no active demo parcel to track.',
            ),
            const SizedBox(height: AppSpacing.md),
            TonalButton(
              label: 'Start a demo parcel',
              icon: Icons.inventory_2_rounded,
              onPressed: () => context.goNamed(AppRoutes.sendName),
            ),
          ],
        ),
      );
    }

    if (parcel.stage == SendStage.delivered ||
        parcel.stage == SendStage.receipt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacementNamed(AppRoutes.sendReceiptName);
      });
    }

    return FixtureGate(
      loading: const Center(child: CircularProgressIndicator()),
      builder: (context, bundle) =>
          _TrackingBody(parcel: parcel, bundle: bundle),
    );
  }
}

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({required this.parcel, required this.bundle});

  final ParcelDelivery parcel;
  final FixtureBundle bundle;

  static const List<(SendStage, String)> _steps = [
    (SendStage.matchingCourier, 'Matching a demo courier'),
    (SendStage.courierAssigned, 'Courier assigned'),
    (SendStage.pickedUp, 'Parcel picked up'),
    (SendStage.inTransit, 'In transit'),
    (SendStage.delivered, 'Delivered'),
  ];

  static const Map<SendStage, int> _rank = {
    SendStage.matchingCourier: 0,
    SendStage.courierAssigned: 1,
    SendStage.pickedUp: 2,
    SendStage.inTransit: 3,
    SendStage.delivered: 4,
    SendStage.receipt: 4,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = _rank[parcel.stage] ?? 0;
    final courier = parcel.courierId == null
        ? null
        : bundle.driver(parcel.courierId!);

    final home = bundle.defaultPickup.point;
    final origin = MapPoint(
      x: (home.x - 0.16).clamp(0.0, 1.0),
      y: (home.y - 0.24).clamp(0.0, 1.0),
    );
    final progress = switch (parcel.stage) {
      SendStage.matchingCourier => 0.0,
      SendStage.courierAssigned => 0.15,
      SendStage.pickedUp => 0.4,
      SendStage.inTransit => 0.7,
      SendStage.delivered => 1.0,
      SendStage.receipt => 1.0,
      _ => 0.0,
    };

    return AppPage(
      title: 'Demo parcel',
      subtitle: '${parcel.senderName} → ${parcel.recipientName}',
      leading: AppBackButton(
        onPressed: () => context.goNamed(AppRoutes.homeName),
      ),
      footer: parcel.stage.isCancellable
          ? TonalButton(
              label: 'Cancel demo parcel',
              icon: Icons.close_rounded,
              onPressed: () => _confirmCancel(context, ref),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xs),
          SchematicMap(
            height: 200,
            origin: origin,
            destination: home,
            route: [origin, home],
            marker: MapPoint.lerp(origin, home, progress),
            markerIcon: Icons.two_wheeler_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, step) in _steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          index <= rank
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: index <= rank
                              ? AppColors.success
                              : AppColors.neutralGray,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            step.$2,
                            style: AppTypography.bodyMuted.copyWith(
                              color: index <= rank
                                  ? AppColors.deepNavy
                                  : AppColors.neutralGray,
                            ),
                          ),
                        ),
                        Text(
                          index <= rank ? 'Done' : 'Pending',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (courier != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppCard(
              semanticLabel: 'Demo courier ${courier.displayName}',
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.tile,
                    child: Image.asset(
                      ImageAssets.resolve(courier.avatarAsset),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        width: 48,
                        height: 48,
                        color: AppColors.indigoTint,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courier.displayName,
                          style: AppTypography.itemTitle,
                        ),
                        Text(
                          'Demo courier · ${courier.rating} ★',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const AppNotice(
            message:
                'Pickup and delivery progress are simulated locally. No GPS '
                'or live tracking is used.',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this demo parcel?'),
        content: const Text(
          'The simulated delivery will stop. Any demo wallet amount is '
          'returned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep parcel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel parcel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(sendProvider.notifier).cancel();
    context.goNamed(AppRoutes.homeName);
  }
}
