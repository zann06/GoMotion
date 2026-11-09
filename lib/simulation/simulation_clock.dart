import 'dart:async';

/// Cancels a single scheduled simulation task.
typedef CancelTask = void Function();

/// Injectable time source for the simulation engine.
///
/// `docs/SIMULATION_ENGINE.md` requires that widgets never call
/// `Future.delayed` directly, that production uses a real timer, and that tests
/// use an explicitly advanced fake clock. Everything needing elapsed time
/// depends on this interface.
abstract interface class SimulationClock {
  /// Current simulation time.
  DateTime now();

  /// Schedules [callback] after [delay] and returns a cancellation handle.
  ///
  /// Callers must retain the handle so cancellation and reset can invalidate
  /// pending work.
  CancelTask schedule(Duration delay, void Function() callback);

  /// Cancels every outstanding scheduled task. Used by reset.
  void cancelAll();
}

/// Wall-clock implementation backed by [Timer].
final class RealSimulationClock implements SimulationClock {
  RealSimulationClock();

  final Set<_ScheduledTask> _live = <_ScheduledTask>{};
  int _generation = 0;

  @override
  DateTime now() => DateTime.now();

  @override
  CancelTask schedule(Duration delay, void Function() callback) {
    final task = _ScheduledTask();
    final generation = _generation;
    task.timer = Timer(delay, () {
      _live.remove(task);
      if (task.cancelled || generation != _generation) return;
      callback();
    });
    _live.add(task);
    return task.cancel;
  }

  @override
  void cancelAll() {
    // Advancing the generation invalidates callbacks that already fired in the
    // same microtask turn, which is what makes stale events harmless on reset.
    _generation++;
    for (final task in _live.toList(growable: false)) {
      task.cancel();
    }
    _live.clear();
  }
}

/// A cancellable timer wrapper with idempotent cancellation.
final class _ScheduledTask {
  late final CancelTask cancel;
  Timer? timer;
  bool cancelled = false;

  _ScheduledTask() {
    cancel = _cancel;
  }

  void _cancel() {
    if (cancelled) return;
    cancelled = true;
    timer?.cancel();
  }
}
