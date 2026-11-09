import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/primary_button.dart';

/// About GoMotion: what this app is, and what it deliberately is not.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<(String, String)> _honesty = [
    (
      'Fully offline',
      'Every screen, journey, and amount comes from bundled demo data. The app '
          'makes no network requests.',
    ),
    (
      'Simulated only',
      'Drivers, couriers, restaurants, parcels, and payments are fictional. '
          'Nothing is booked, dispatched, delivered, or charged.',
    ),
    (
      'No real maps or GPS',
      'The illustrated map is a schematic drawing, not a geographic map. Your '
          'location is never read.',
    ),
    (
      'Session-only data',
      'Activity, wallet balance, points, and saved places live in memory and '
          'are cleared when the simulation is reset.',
    ),
    (
      'Original branding',
      'GoMotion is an original demo identity and is not affiliated with any '
          'real mobility or delivery company.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'About GoMotion',
      subtitle: AppInfo.tagline,
      leading: const AppBackButton(),
      footer: PrimaryButton(
        label: 'Back to settings',
        icon: Icons.arrow_back_rounded,
        onPressed: () => context.pop(),
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
                    ClipRRect(
                      borderRadius: AppRadius.tile,
                      child: Image.asset(
                        ImageAssets.brandMark,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: 44,
                          height: 44,
                          color: AppColors.indigoTint,
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppInfo.name, style: AppTypography.section),
                          Text(
                            'Version ${AppInfo.version} · demo build',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const StatusPill(label: DemoCopy.pill),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  AppInfo.offlineNotice,
                  style: AppTypography.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'How this demo works'),
          const SizedBox(height: AppSpacing.xs),
          for (final (title, body) in _honesty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.primaryIndigo,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(title, style: AppTypography.itemTitle),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(body, style: AppTypography.bodyMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xs),
          const AppNotice(
            message:
                'GoMotion demonstrates interaction patterns only. It is not a '
                'transportation, delivery, or payment service.',
          ),
        ],
      ),
    );
  }
}
