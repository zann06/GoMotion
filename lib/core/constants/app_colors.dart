import 'package:flutter/material.dart';

/// GoMotion brand colour tokens.
///
/// Values are fixed by `docs/DESIGN_SYSTEM.md`. Indigo, blue, and violet are the
/// only brand primaries; [success] is reserved for semantic success states and
/// schematic map detail, never for primary actions.
@immutable
abstract final class AppColors {
  /// Primary actions, active states.
  static const Color primaryIndigo = Color(0xFF4F46E5);

  /// Links and secondary emphasis.
  static const Color electricBlue = Color(0xFF2563EB);

  /// Accent and gradient endpoint.
  static const Color violet = Color(0xFF8B5CF6);

  /// Main text and dark surfaces.
  static const Color deepNavy = Color(0xFF111827);

  /// Application background.
  static const Color softWhite = Color(0xFFF5F6FF);

  /// Cards, sheets, and elevated surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Secondary text and inactive icons.
  static const Color neutralGray = Color(0xFF64748B);

  /// Dividers and outlines.
  static const Color lightBorder = Color(0xFFE5E7EB);

  /// Semantic success only. Never use as the brand primary.
  static const Color success = Color(0xFF16A34A);

  /// Semantic warning, used for recoverable demo-state notices.
  static const Color warning = Color(0xFFB45309);

  /// Semantic error, used for failed or blocked actions.
  static const Color error = Color(0xFFDC2626);

  /// Tinted indigo surface for pills, icon wells, and selected rows.
  static const Color indigoTint = Color(0xFFEEEBFF);

  /// Tinted blue surface, a slightly cooler companion to [indigoTint].
  static const Color blueTint = Color(0xFFE8EFFF);

  /// Tinted success surface for schematic park blocks.
  static const Color successTint = Color(0xFFDCEFE0);

  /// Tinted warning surface.
  static const Color warningTint = Color(0xFFFDF3E3);

  /// Tinted error surface.
  static const Color errorTint = Color(0xFFFDECEC);

  /// Muted surface for shimmer/skeleton placeholders.
  static const Color skeleton = Color(0xFFEDEFFA);

  /// The brand gradient used by primary CTAs and hero surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryIndigo, electricBlue, violet],
  );

  /// A restrained two-stop gradient for hero cards. The design system asks for
  /// restrained gradients, so this stops at blue rather than sweeping to violet.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryIndigo, electricBlue],
  );

  /// Schematic map ground colour.
  static const Color mapGround = Color(0xFFE9EBF9);

  /// Schematic map road colour.
  static const Color mapRoad = Color(0xFFFFFFFF);
}
