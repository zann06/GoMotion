import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/reduced_motion_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// The primary call to action: a restrained indigo→blue→violet gradient.
///
/// States: default, pressed (scale + tonal response), disabled, and loading.
/// While [loading] the button is non-interactive and exposes the busy state to
/// assistive technology, which also prevents duplicate submissions.
class PrimaryButton extends ConsumerStatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
    super.key,
  });

  final String label;

  /// Invoked on tap. Passing null disables the button.
  final VoidCallback? onPressed;

  final IconData? icon;

  /// Shows an inline spinner and blocks further taps.
  final bool loading;

  /// Whether to fill the available width.
  final bool expand;

  /// Optional richer semantics label for screen readers.
  final String? semanticLabel;

  @override
  ConsumerState<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends ConsumerState<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final motion = ref.watch(reduceMotionProvider);
    final scale = _pressed && _enabled ? 0.98 : 1.0;

    return Semantics(
      button: true,
      enabled: _enabled,
      liveRegion: widget.loading,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: scale,
        duration: motion.resolve(AppDuration.press),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _enabled ? 1 : 0.55,
          child: GestureDetector(
            onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
            onTapCancel: _enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTapUp: _enabled
                ? (_) {
                    setState(() => _pressed = false);
                    widget.onPressed?.call();
                  }
                : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.button,
                boxShadow: _enabled
                    ? const [
                        BoxShadow(
                          color: Color(0x334F46E5),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              width: widget.expand ? double.infinity : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.white,
                      ),
                    )
                  else if (widget.icon != null)
                    Icon(widget.icon, size: 18, color: AppColors.white),
                  if (widget.loading || widget.icon != null)
                    const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      widget.loading ? 'Please wait…' : widget.label,
                      style: AppTypography.button,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

/// A lower-emphasis action on a tonal indigo surface.
class TonalButton extends StatelessWidget {
  const TonalButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: enabled ? AppColors.indigoTint : AppColors.skeleton,
        borderRadius: AppRadius.button,
        child: InkWell(
          borderRadius: AppRadius.button,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            width: expand ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: enabled
                        ? AppColors.primaryIndigo
                        : AppColors.neutralGray,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.itemTitle.copyWith(
                      color: enabled
                          ? AppColors.primaryIndigo
                          : AppColors.neutralGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
