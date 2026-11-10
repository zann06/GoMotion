import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'app_motion.dart';

/// A white surface card with a hairline border and subtle shadow.
///
/// The design system prefers clear borders and surface contrast over heavy
/// elevation, so this uses a 1px [AppColors.lightBorder] outline plus a low
/// opacity shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.semanticLabel,
    this.selected = false,
    this.borderColor,
    this.background = AppColors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When provided the card becomes interactive with press feedback.
  final VoidCallback? onTap;

  /// Semantics label describing the card as a whole.
  final String? semanticLabel;

  /// Renders the selected treatment: indigo border and light tint.
  final bool selected;

  /// Overrides the border colour, e.g. for emphasis states.
  final Color? borderColor;

  final Color background;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final effectiveBorder = selected
        ? AppColors.primaryIndigo
        : (borderColor ?? AppColors.lightBorder);
    // Interactive cards get a slightly softer, deeper shadow so the surface
    // reads as liftable rather than printed on the background.
    final shadows = selected
        ? const <BoxShadow>[]
        : (onTap == null ? AppShadows.card : AppShadows.cardLifted);

    final content = AnimatedContainer(
      duration: AppDuration.value,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: effectiveBorder, width: selected ? 1.8 : 1),
        boxShadow: shadows,
      ),
      // A transparent Material gives descendants such as ListTile a surface for
      // ink effects on top of the decorated card.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );

    // The theme disables ink splashes, so an interactive card answers a press
    // with a short scale instead. The feedback wraps the whole surface, so the
    // border and shadow move with it.
    final surface = onTap == null
        ? content
        : AppPressFeedback(onTap: onTap!, child: content);

    if (onTap == null) {
      return Semantics(label: semanticLabel, container: true, child: surface);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      container: true,
      excludeSemantics: semanticLabel != null,
      child: surface,
    );
  }
}

/// A pill-shaped status indicator.
///
/// Status is never conveyed by colour alone: the label text always states the
/// status, satisfying the accessibility rule in `docs/UI_UX_GUIDELINES.md`.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.tone = PillTone.brand,
    this.icon,
    super.key,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.brand => (AppColors.indigoTint, AppColors.primaryIndigo),
      PillTone.neutral => (AppColors.skeleton, AppColors.neutralGray),
      PillTone.success => (AppColors.successTint, AppColors.success),
      PillTone.warning => (AppColors.warningTint, AppColors.warning),
      PillTone.error => (AppColors.errorTint, AppColors.error),
      PillTone.onGradient => (
        Colors.white.withValues(alpha: 0.18),
        AppColors.white,
      ),
    };

    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.chip),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label.toUpperCase(),
              style: AppTypography.pill.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Semantic tones available to [StatusPill].
enum PillTone { brand, neutral, success, warning, error, onGradient }

/// A section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Optional trailing widget, typically a text button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: AppTypography.section),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

/// A label/value row used in fare breakdowns and receipts.
class DetailRow extends StatelessWidget {
  const DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;

  /// Renders the row with stronger weight, used for totals.
  final bool emphasize;

  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? AppTypography.itemTitle : AppTypography.bodyMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: emphasize
                ? AppTypography.amount
                : style.copyWith(
                    color: valueColor ?? AppColors.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }
}
