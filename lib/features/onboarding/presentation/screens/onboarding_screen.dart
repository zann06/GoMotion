import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/mascot.dart';
import '../../../../core/widgets/primary_button.dart';

/// First-launch welcome.
///
/// Explains plainly that GoMotion is an offline simulation, then hands off to
/// the home screen. Presented once; the choice is a simple local preference.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _saving = false;

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);

    await ref.read(preferencesStoreProvider).setHasSeenOnboarding(true);
    if (!mounted) return;

    context.goNamed(AppRoutes.homeName);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: AppInfo.name,
      subtitle: AppInfo.tagline,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppNotice(
            message:
                'GoMotion is an original demo identity. It is not affiliated '
                'with any real mobility or delivery company.',
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Explore the demo',
            icon: Icons.arrow_forward_rounded,
            loading: _saving,
            onPressed: _continue,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 190,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.hero,
            ),
            child: const Center(
              child: Mascot(variant: MascotVariant.wave, size: MascotSize.hero),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final (icon, title, body) in _points) ...[
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: AppColors.primaryIndigo),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.itemTitle),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(body, style: AppTypography.bodyMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static const List<(IconData, String, String)> _points = [
    (
      Icons.directions_car_rounded,
      'Three simulated services',
      'Take a demo ride, order fictional food, or send a demo parcel — all '
          'from one app.',
    ),
    (
      Icons.wifi_off_rounded,
      'Works fully offline',
      'Every screen and amount comes from bundled demo data. No network, maps, '
          'GPS, or payments are used.',
    ),
    (
      Icons.auto_awesome_rounded,
      'Nothing is real',
      'Drivers, restaurants, prices, and receipts are fictional sample data '
          'created for this demo.',
    ),
  ];
}
