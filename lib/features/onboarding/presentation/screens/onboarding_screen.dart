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
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_motion.dart';
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
          const SizedBox(height: AppSpacing.sm),
          // Hero: a soft brand surface that holds the lock-up and the mascot
          // together, so the first screen after the splash continues the brand
          // rather than restarting with a bare card.
          AppReveal(
            offset: 0.07,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: AppRadius.hero,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlue.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              // The hero sizes to its content with a 208px floor: a fixed height
              // would clip the lock-up at a raised text scale.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 208),
                child: const Stack(
                  children: [
                    // Faint orbit rings add depth without competing with
                    // content.
                    Positioned(
                      right: -28,
                      top: -34,
                      child: _OrbitRing(size: 168, opacity: 0.14),
                    ),
                    Positioned(
                      right: 26,
                      bottom: -54,
                      child: _OrbitRing(size: 132, opacity: 0.10),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppBrandLockup(
                              markSize: 44,
                              showTagline: true,
                              foreground: AppColors.white,
                              markForeground: AppColors.white,
                              gradient: null,
                            ),
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Mascot(
                            variant: MascotVariant.wave,
                            size: MascotSize.hero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final (index, (icon, title, bodyPoint)) in _points.indexed) ...[
            AppReveal(
              index: index + 1,
              child: AppCard(
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
                          Text(bodyPoint, style: AppTypography.bodyMuted),
                        ],
                      ),
                    ),
                  ],
                ),
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

/// A faint concentric ring used to give the hero surface depth.
class _OrbitRing extends StatelessWidget {
  const _OrbitRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
