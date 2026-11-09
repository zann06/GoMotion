import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographic scale from `docs/DESIGN_SYSTEM.md`.
///
/// Hierarchy: display 28–32/700, title 22–24/700, section 16–18/650,
/// body 14–16/400, caption 11–12/500.
///
/// The package ships no licensed font files, and the design system explicitly
/// permits the platform sans-serif in that case, so the family is left null.
@immutable
abstract final class AppTypography {
  static const String? _family = null;

  /// Screen-level greeting, e.g. "Good afternoon, Alex".
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 30,
    height: 1.16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.deepNavy,
  );

  /// Screen title used by flow pages, e.g. "Choose your ride".
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.deepNavy,
  );

  /// Section heading inside a screen, e.g. "Popular restaurants".
  static const TextStyle section = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.deepNavy,
  );

  /// Card and list-row primary label.
  static const TextStyle itemTitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.deepNavy,
  );

  /// Default body copy.
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.deepNavy,
  );

  /// Secondary supporting copy.
  static const TextStyle bodyMuted = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralGray,
  );

  /// Screen subtitle shown under a [title] or [display].
  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralGray,
  );

  /// Small labels and metadata.
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.neutralGray,
  );

  /// Emphasised numeric value such as a fare.
  static const TextStyle amount = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.primaryIndigo,
  );

  /// Large numeric value used on receipts.
  static const TextStyle amountLarge = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.deepNavy,
  );

  /// Uppercase pill/status label.
  static const TextStyle pill = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.primaryIndigo,
  );

  /// Primary CTA label.
  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.white,
  );

  /// On-gradient heading, e.g. "Your next journey".
  static const TextStyle onGradientTitle = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.white,
  );

  /// On-gradient supporting copy.
  static const TextStyle onGradientBody = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: Color(0xE6FFFFFF),
  );
}
