import 'simulation_clock.dart';

/// A deterministic clock for tests.
///
/// Time only advances when a test explicitly calls [advance]. Callbacks run in
/// scheduled order, so lifecycle assertions are reproducible and never depend
/// on real wall-clock timing.
final class FakeSimulationClock implements SimulationClock {
  FakeSimulationClock({DateTime? start})
    : _now = start ?? DateTime.utc(2026, 1, 1, 9, 41);

  DateTime _now;
  int _sequence = 0;

  final List<_FakeTask> _pending = <_FakeTask>[];
  int _generation = 0;

  /// Number of tasks currently awaiting execution. Useful for asserting that
  /// cancellation and reset leave no timers behind.
  int get pendingCount => _pending.length;

  @override
  DateTime now() => _now;

  @override
  CancelTask schedule(Duration delay, void Function() callback) {
    final task = _FakeTask(
      dueAt: _now.add(delay),
      sequence: _sequence++,
      callback: callback,
      generation: _generation,
    );
    _pending.add(task);
    return () {
      task.cancelled = true;
      _pending.remove(task);
    };
  }

  @override
  void cancelAll() {
    _generation++;
    for (final task in _pending) {
      task.cancelled = true;
    }
    _pending.clear();
  }

  /// Advances simulated time by [duration], running every task that comes due.
  ///
  /// Tasks scheduled by a callback during this call are honoured if they fall
  /// inside the remaining window, which mirrors real timer behaviour.
  void advance(Duration duration) {
    final target = _now.add(duration);
    while (true) {
      _pending.sort((a, b) {
        final byDue = a.dueAt.compareTo(b.dueAt);
        return byDue != 0 ? byDue : a.sequence.compareTo(b.sequence);
      });
      if (_pending.isEmpty) break;
      final next = _pending.first;
      if (next.dueAt.isAfter(target)) break;
      _pending.removeAt(0);
      if (next.cancelled || next.generation != _generation) continue;
      _now = next.dueAt;
      next.callback();
    }
    _now = target;
  }
}

final class _FakeTask {
  _FakeTask({
    required this.dueAt,
    required this.sequence,
    required this.callback,
    required this.generation,
  });

  final DateTime dueAt;
  final int sequence;
  final void Function() callback;
  final int generation;
  bool cancelled = false;
}
