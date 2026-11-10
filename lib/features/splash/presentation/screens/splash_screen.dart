import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_motion.dart';
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
      // The progress indicator sits outside the centred column so a large text
      // scale can never push it off the screen: the centre block stays centred
      // and the loader keeps its own row at the bottom.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppReveal(
                  index: 3,
                  offset: 0.04,
                  child: ClipRRect(
                    borderRadius: AppRadius.chip,
                    child: SizedBox(
                      width: 168,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => AppProgressBar(
                          value: _controller.value,
                          height: 5,
                          color: AppColors.white,
                          trackColor: AppColors.white.withValues(alpha: 0.22),
                          semanticLabel: 'Loading',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const MascotLoadingDots(),
                const SizedBox(height: AppSpacing.md),
                AppReveal(
                  index: 4,
                  offset: 0.04,
                  child: Text(
                    'Offline demo — no network, GPS, or payments',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppSplashSignature(),
                  const SizedBox(height: AppSpacing.xl),
                  AppReveal(
                    index: 1,
                    offset: 0.06,
                    child: Text(
                      AppInfo.name,
                      style: AppTypography.display.copyWith(
                        color: AppColors.white,
                        letterSpacing: -1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const AppReveal(
                    index: 2,
                    offset: 0.06,
                    child: Text(
                      AppInfo.tagline,
                      style: AppTypography.onGradientBody,
                      textAlign: TextAlign.center,
                    ),
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
