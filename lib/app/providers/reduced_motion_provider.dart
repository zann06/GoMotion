import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_spacing.dart';

/// Whether the user has disabled animations at the OS level.
@immutable
class SystemReduceMotion {
  const SystemReduceMotion({required this.enabled});

  final bool enabled;

  @override
  bool operator ==(Object other) =>
      other is SystemReduceMotion && other.enabled == enabled;

  @override
  int get hashCode => enabled.hashCode;
}

/// Reflects `MediaQuery.disableAnimations` into provider space.
///
/// The root widget writes to this notifier whenever the media query changes, so
/// provider consumers stay in sync without reaching for `BuildContext`.
final systemReduceMotionProvider =
    NotifierProvider<SystemReduceMotionNotifier, SystemReduceMotion>(
      SystemReduceMotionNotifier.new,
    );

/// Holds the platform's reduced-motion setting.
final class SystemReduceMotionNotifier extends Notifier<SystemReduceMotion> {
  @override
  SystemReduceMotion build() => const SystemReduceMotion(enabled: false);

  /// Records the current platform setting, ignoring no-op writes.
  void sync(bool enabled) {
    if (state.enabled == enabled) return;
    state = SystemReduceMotion(enabled: enabled);
  }
}

/// The user's explicit in-app motion override.
final inAppReduceMotionProvider = NotifierProvider<InAppReduceMotion, bool>(
  InAppReduceMotion.new,
);

/// Stores the explicit in-app motion preference.
final class InAppReduceMotion extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state == value) return;
    state = value;
  }

  void toggle() => state = !state;
}

/// Resolves the effective motion preference for the whole app.
///
/// A user who enables reduced motion in-app, or who has it enabled at the OS
/// level, never receives decorative motion.
@immutable
class ReduceMotion {
  const ReduceMotion({required this.enabled});

  final bool enabled;

  /// Collapses [duration] to a short fade when motion is reduced.
  Duration resolve(Duration duration) =>
      enabled ? AppDuration.reduced : duration;

  /// Zero-duration when reduced, for purely decorative animations.
  Duration get decorative => enabled ? Duration.zero : AppDuration.enter;

  /// Whether looping decorative animations (e.g. the matching radar) run.
  bool get allowLoops => !enabled;
}

/// The single source of truth for effective motion preferences.
final reduceMotionProvider = Provider<ReduceMotion>((ref) {
  final system = ref.watch(systemReduceMotionProvider).enabled;
  final inApp = ref.watch(inAppReduceMotionProvider);
  return ReduceMotion(enabled: system || inApp);
});
