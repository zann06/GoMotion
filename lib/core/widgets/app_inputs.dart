import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// A labelled text field matching the GoMotion visual language.
///
/// Wraps [TextField] so every form in the app shares the same border, error
/// treatment, and 48dp minimum height. The error text is always rendered as
/// text, never as a red border alone, so colour is not the only signal.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;

  /// Optional trailing widget, e.g. a clear button.
  final Widget? suffix;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          textField: true,
          label: semanticLabel ?? label,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            maxLength: maxLength,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.body,
            cursorColor: AppColors.primaryIndigo,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMuted,
              counterText: '',
              isDense: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(prefixIcon, size: 20, color: AppColors.neutralGray),
              suffixIcon: suffix,
              enabledBorder: _border(
                hasError ? AppColors.error : AppColors.lightBorder,
              ),
              focusedBorder: _border(
                hasError ? AppColors.error : AppColors.primaryIndigo,
              ),
              errorBorder: _border(AppColors.error),
              focusedErrorBorder: _border(AppColors.error),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppRadius.button,
    borderSide: BorderSide(color: color, width: 1.2),
  );
}

/// A large tappable row used for destinations, vehicles, and settings entries.
///
/// Guarantees the 48dp minimum target and exposes selection state to assistive
/// technology rather than relying on colour.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.semanticLabel,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.sm);
    final content = Container(
      constraints: const BoxConstraints(minHeight: kMinTouchTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.indigoTint : Colors.transparent,
        borderRadius: radius,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, container: true, child: content);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      ),
    );
  }
}

/// A rounded icon well used as the leading element of list rows.
class IconWell extends StatelessWidget {
  const IconWell({
    required this.icon,
    this.background = AppColors.indigoTint,
    this.foreground = AppColors.primaryIndigo,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.tile,
      ),
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

/// A compact quantity stepper used by the food cart.
///
/// Both buttons keep a 48dp target even though the visual chip is smaller, and
/// the current quantity is announced with its meaning rather than as a bare
/// number.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.itemName,
    super.key,
  });

  final int quantity;
  final VoidCallback onIncrement;

  /// Null disables the decrement control, e.g. at the minimum quantity.
  final VoidCallback? onDecrement;

  final String? itemName;

  @override
  Widget build(BuildContext context) {
    final name = itemName ?? 'item';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onPressed: onDecrement,
          semanticLabel: 'Remove one $name',
        ),
        SizedBox(
          width: 32,
          child: Semantics(
            label: '$quantity $name in cart',
            excludeSemantics: true,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.itemTitle,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          onPressed: onIncrement,
          semanticLabel: 'Add one $name',
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Center(
          child: Material(
            color: enabled ? AppColors.indigoTint : AppColors.skeleton,
            borderRadius: AppRadius.chip,
            child: InkWell(
              borderRadius: AppRadius.chip,
              onTap: onPressed,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled
                      ? AppColors.primaryIndigo
                      : AppColors.neutralGray,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
