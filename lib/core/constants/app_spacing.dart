import 'package:flutter/widgets.dart';

/// Layout tokens on an 8-point base grid, per `docs/DESIGN_SYSTEM.md`.
@immutable
abstract final class AppSpacing {
  /// 4 — hairline gaps between tightly related labels.
  static const double xxs = 4;

  /// 8 — base unit.
  static const double xs = 8;

  /// 12 — gap between stacked cards in a dense list.
  static const double sm = 12;

  /// 16 — gap between related content blocks.
  static const double md = 16;

  /// 20 — the documented screen horizontal padding.
  static const double lg = 20;

  /// 24 — generous section separation.
  static const double xl = 24;

  /// 32 — major section breaks.
  static const double xxl = 32;

  /// 40 — hero/splash rhythm.
  static const double xxxl = 40;

  /// Horizontal page padding applied by [AppPage].
  static const double pageGutter = lg;
}

/// Corner radius tokens.
@immutable
abstract final class AppRadius {
  /// 12 — small inner tiles.
  static const double xs = 12;

  /// 16 — buttons, inputs.
  static const double sm = 16;

  /// 20 — cards and list rows.
  static const double md = 20;

  /// 24 — hero cards and sheets.
  static const double lg = 24;

  /// Fully rounded, used by chips and status pills.
  static const double pill = 999;

  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius hero = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius tile = BorderRadius.all(Radius.circular(xs));
}

/// Motion tokens from `docs/ANIMATION_SPECIFICATION.md`.
@immutable
abstract final class AppDuration {
  /// Press feedback: 90–140 ms.
  static const Duration press = Duration(milliseconds: 110);

  /// Enter/exit transitions: 180–280 ms.
  static const Duration enter = Duration(milliseconds: 220);

  /// Slightly longer exit for dismissal.
  static const Duration exit = Duration(milliseconds: 180);

  /// Number and ETA transitions: 180–240 ms.
  static const Duration value = Duration(milliseconds: 200);

  /// Bottom sheet: 260–340 ms with a restrained spring.
  static const Duration sheet = Duration(milliseconds: 300);

  /// Success moment: 500–900 ms.
  static const Duration success = Duration(milliseconds: 650);

  /// Radar loop: 1.8–2.4 s.
  static const Duration radar = Duration(milliseconds: 2100);

  /// Reduced-motion substitute for decorative transitions.
  static const Duration reduced = Duration(milliseconds: 90);
}

/// Elevation and shadow tokens. The design system asks for subtle shadows, so
/// these stay low-opacity and low-blur.
@immutable
abstract final class AppShadows {
  /// Resting card shadow.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D111827), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Raised surface, such as a sticky CTA bar.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x14111827), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Minimum interactive target size from the design system.
const double kMinTouchTarget = 48;

/// Maximum content width. Prevents very wide layouts on tablets and foldables.
const double kMaxContentWidth = 560;
