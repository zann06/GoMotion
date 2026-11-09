import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/mascot_assets.dart';
import 'mascot.dart';
import 'primary_button.dart';

/// A screen-level loading state with a shimmering skeleton.
///
/// Skeletons are preferred over spinners for list-shaped content because they
/// communicate the shape of what is arriving.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({this.itemCount = 3, this.itemHeight = 84, super.key});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    // Shrink-wrapped and non-scrollable so the skeleton can be embedded inside
    // a page that already scrolls (search results, detail bodies) without
    // triggering an unbounded-viewport failure.
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageGutter,
        vertical: AppSpacing.md,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => _ShimmerBlock(height: itemHeight),
    );
  }
}

/// A single shimmering placeholder block.
class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height});

  final double height;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour reduced motion: hold the placeholder still instead of sweeping.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.stop();
      _controller.value = 0.4;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(t * 2, 0),
                colors: const [
                  AppColors.skeleton,
                  Color(0xFFF7F8FE),
                  AppColors.skeleton,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A friendly empty state that always offers a local next action.
///
/// `docs/UI_UX_GUIDELINES.md` requires explaining why a list is empty and
/// offering a local next step.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.mascot,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// When set, the mascot illustrates the state instead of a plain icon.
  final MascotVariant? mascot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StateArt(
              icon: icon,
              background: AppColors.indigoTint,
              foreground: AppColors.primaryIndigo,
              mascot: mascot,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: TonalButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An inline informational banner.
///
/// Used for recoverable guidance ("choose a destination first") and for demo
/// honesty notices. The [tone] changes the accent and icon, and the message is
/// always plain text, so meaning never depends on colour alone.
class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.message,
    this.tone = NoticeTone.info,
    this.icon,
    super.key,
  });

  final String message;
  final NoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, defaultIcon) = switch (tone) {
      NoticeTone.info => (
        AppColors.blueTint,
        AppColors.electricBlue,
        Icons.info_outline_rounded,
      ),
      NoticeTone.warning => (
        AppColors.warningTint,
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      NoticeTone.error => (
        AppColors.errorTint,
        AppColors.error,
        Icons.error_outline_rounded,
      ),
      NoticeTone.success => (
        AppColors.successTint,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.button,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMuted.copyWith(
                  color: AppColors.deepNavy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Semantic tone for [AppNotice].
enum NoticeTone { info, warning, error, success }

/// A recoverable error state.
///
/// Never displays stack traces or asset paths; the technical cause stays in
/// debug logs, per `docs/ARCHITECTURE.md`.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.mascot,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  /// When set, the mascot illustrates the failure instead of a plain icon.
  final MascotVariant? mascot;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StateArt(
              icon: Icons.error_outline_rounded,
              background: AppColors.errorTint,
              foreground: AppColors.error,
              mascot: mascot,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodyMuted,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: TonalButton(label: retryLabel, onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Illustrates a state with the mascot when one is provided, or a tinted icon
/// otherwise. Keeping both paths here means every empty/error screen shares one
/// visual treatment.
class _StateArt extends StatelessWidget {
  const _StateArt({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.mascot,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final MascotVariant? mascot;

  @override
  Widget build(BuildContext context) {
    final variant = mascot;
    if (variant != null) {
      return Mascot(variant: variant, size: MascotSize.large);
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 28, color: foreground),
    );
  }
}
