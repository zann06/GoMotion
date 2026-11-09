import 'package:flutter/services.dart';

/// A small, deliberate haptic vocabulary.
///
/// Haptics only reinforce a result the user already sees; they never carry
/// meaning on their own, per `docs/UI_UX_GUIDELINES.md`. Every call is a safe
/// no-op on platforms (and in tests) without a haptic engine.
abstract final class AppHaptics {
  /// A lightweight selection tick, used for navigation and discrete choices.
  static void select() {
    HapticFeedback.selectionClick();
  }

  /// A slightly firmer tap, used when a simulated commitment is confirmed.
  static void confirm() {
    HapticFeedback.lightImpact();
  }
}
