import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../domain/entities/fixtures.dart';

/// The demo driver's identity card, shared by matching and live tracking.
///
/// On the live screen the reference shows the driver, their plate, and a call
/// affordance; during matching the same card reads as a reveal. Keeping one
/// widget means the driver never changes shape between the two screens.
///
/// The call button is deliberately a sheet, not a dialer: the demo cannot place
/// calls, so tapping explains that instead of opening the phone app.
class DriverCard extends StatelessWidget {
  const DriverCard({
    required this.driver,
    required this.vehicle,
    required this.status,
    this.trailing,
    this.showCall = true,
    super.key,
  });

  final Driver driver;

  /// The booked vehicle, used for the plate and the model line.
  final Vehicle? vehicle;

  /// Short stage label, e.g. `Arriving in 2 min`.
  final String status;

  /// Optional extra action rendered under the driver row.
  final Widget? trailing;

  /// Whether to render the demo call button.
  final bool showCall;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle?.plate ?? '';
    final vehicleLabel = vehicle?.label ?? '';
    final model = plate.isEmpty ? vehicleLabel : '$vehicleLabel · $plate';

    return AppCard(
      semanticLabel:
          '${DemoCopy.driver} ${driver.displayName}, rating ${driver.rating}, '
          '$model, $status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(driver: driver),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.displayName,
                      style: AppTypography.itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${driver.rating} · '
                            '${driver.completedDemoTrips} demo trips',
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showCall) ...[
                const SizedBox(width: AppSpacing.xs),
                _CallButton(driverName: driver.displayName),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Vehicle line: the plate follows the category inside one flexible
          // group, so a long "GoCar Premium" label truncates before the plate
          // ever does, and the status keeps its intrinsic width.
          Row(
            children: [
              const Icon(
                AppIcons.vehicle,
                size: 16,
                color: AppColors.primaryIndigo,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: vehicleLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (plate.isNotEmpty)
                        TextSpan(
                          text: ' · $plate',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status,
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryIndigo,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.driver});

  final Driver driver;

  static const double _size = 54;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.tile,
      child: Image.asset(
        ImageAssets.resolve(driver.avatarAsset),
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        // A missing optional avatar degrades to an icon, never a crash.
        errorBuilder: (context, error, stack) => Container(
          width: _size,
          height: _size,
          color: AppColors.indigoTint,
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primaryIndigo,
          ),
        ),
      ),
    );
  }
}

/// A demo-only call affordance.
///
/// Opens a sheet rather than a `tel:` link, because the product is offline and
/// must never imply a real phone call was placed.
class _CallButton extends StatelessWidget {
  const _CallButton({required this.driverName});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Call $driverName (demo)',
      child: Material(
        color: AppColors.indigoTint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _explainDemoCall(context),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.call_rounded,
              size: 20,
              color: AppColors.primaryIndigo,
            ),
          ),
        ),
      ),
    );
  }

  void _explainDemoCall(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Calling is simulated', style: AppTypography.section),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$driverName is a fictional demo driver. This app works fully '
              'offline, so no call is placed and no phone number is stored.',
              style: AppTypography.bodyMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
