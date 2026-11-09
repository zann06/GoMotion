import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/mascot.dart';

/// First frame of the app: the mascot waves hello while a short brand progress
/// bar fills, then the app hands off to the welcome screen or the dashboard.
///
/// The hand-off is driven by a completing animation rather than a timer, so the
/// splash never leaves a dangling timer behind and always advances with frames.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    final reduced = ref.read(reduceMotionProvider).enabled;
    _controller = AnimationController(
      vsync: this,
      duration: reduced
          ? const Duration(milliseconds: 600)
          : const Duration(milliseconds: 1300),
    );
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Navigate after the frame that completed the animation.
    WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
  }

  void _advance() {
    if (_advanced || !mounted) return;
    _advanced = true;
    final seen = ref.read(preferencesStoreProvider).hasSeenOnboarding;
    context.goNamed(seen ? AppRoutes.homeName : AppRoutes.onboardingName);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlue,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Mascot(
                    variant: MascotVariant.wave,
                    size: MascotSize.hero,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    AppInfo.name,
                    style: AppTypography.display.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  const Text(
                    AppInfo.tagline,
                    style: AppTypography.onGradientBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ClipRRect(
                    borderRadius: AppRadius.chip,
                    child: SizedBox(
                      width: 148,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 5,
                          backgroundColor: AppColors.white.withValues(
                            alpha: 0.22,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const MascotLoadingDots(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Offline demo — no network, GPS, or payments',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
