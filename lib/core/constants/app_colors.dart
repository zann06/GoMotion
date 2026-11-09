import 'package:flutter/material.dart';

/// GoMotion brand colour tokens.
///
/// Refreshed to a deep-blue identity (`docs/DESIGN_SYSTEM.md`,
/// `docs/DESIGN_REFRESH.md`). Blue is the primary family; violet is kept as a
/// small tertiary accent and [success] is reserved for semantic success states
/// and schematic map detail, never for primary actions.
@immutable
abstract final class AppColors {
  /// Deepest brand blue. Hero gradient start and dark brand surfaces.
  static const Color deepBlue = Color(0xFF0E2A6E);

  /// Primary actions, active states.
  static const Color primaryIndigo = Color(0xFF1D4ED8);

  /// Links and secondary emphasis.
  static const Color electricBlue = Color(0xFF2563EB);

  /// Bright decorative blue for map and illustration detail.
  static const Color brightBlue = Color(0xFF3B82F6);

  /// Tertiary accent, used sparingly for the Send service and badges.
  static const Color violet = Color(0xFF7C3AED);

  /// Main text and dark surfaces.
  static const Color deepNavy = Color(0xFF0B1220);

  /// Application background.
  static const Color softWhite = Color(0xFFF3F6FE);

  /// Cards, sheets, and elevated surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Secondary text and inactive icons.
  static const Color neutralGray = Color(0xFF5B6B85);

  /// Dividers and outlines.
  static const Color lightBorder = Color(0xFFE2E8F5);

  /// Semantic success only. Never use as the brand primary.
  static const Color success = Color(0xFF16A34A);

  /// Semantic warning, used for recoverable demo-state notices.
  static const Color warning = Color(0xFFB45309);

  /// Semantic error, used for failed or blocked actions.
  static const Color error = Color(0xFFDC2626);

  /// Tinted blue surface for pills, icon wells, and selected rows.
  static const Color indigoTint = Color(0xFFE8EEFF);

  /// Tinted blue surface, a slightly cooler companion to [indigoTint].
  static const Color blueTint = Color(0xFFE6F0FF);

  /// Tinted success surface for schematic park blocks.
  static const Color successTint = Color(0xFFDCEFE0);

  /// Tinted warning surface.
  static const Color warningTint = Color(0xFFFDF3E3);

  /// Tinted error surface.
  static const Color errorTint = Color(0xFFFDECEC);

  /// Muted surface for shimmer/skeleton placeholders.
  static const Color skeleton = Color(0xFFE9EEF9);

  /// The brand gradient used by primary CTAs and hero surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepBlue, primaryIndigo, electricBlue],
  );

  /// A restrained two-stop gradient for hero cards. Deep blue into the primary
  /// action blue keeps the surface calm and premium.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, primaryIndigo],
  );

  /// A softer blue wash used behind the home search field and map overlays.
  static const LinearGradient heroWash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlue, electricBlue],
  );

  /// Schematic map ground colour.
  static const Color mapGround = Color(0xFFE7ECFA);

  /// Schematic map road colour.
  static const Color mapRoad = Color(0xFFFFFFFF);

  /// Schematic map building blocks.
  static const Color mapBlock = Color(0xFFDCE4F7);

  /// Schematic map building block, alternate tone for depth.
  static const Color mapBlockAlt = Color(0xFFD2DCF4);

  /// Schematic map road casing, drawn under the white road surface.
  static const Color mapRoadCasing = Color(0xFFD3DDF3);
}
