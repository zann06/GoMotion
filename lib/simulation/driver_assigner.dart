import '../domain/entities/fixtures.dart';

/// Deterministic driver assignment.
///
/// `docs/SIMULATION_ENGINE.md` requires that assignment be reproducible from a
/// stable seed derived from the ride id. The same ride id must always yield the
/// same driver, in tests and at runtime, without any random source.
abstract final class DriverAssigner {
  /// Picks a driver for [rideId] from [candidates].
  ///
  /// When [candidates] is empty this returns null and callers surface a
  /// recoverable "no driver" state rather than crashing.
  static Driver? assign({
    required String rideId,
    required List<Driver> candidates,
    int seed = 0,
  }) {
    if (candidates.isEmpty) return null;
    final ordered = [...candidates]
      ..sort((a, b) => a.seedOrder.compareTo(b.seedOrder));
    final index = _stableHash(rideId, seed) % ordered.length;
    return ordered[index];
  }

  /// A small, platform-stable hash.
  ///
  /// Dart's `String.hashCode` is not guaranteed stable across releases or
  /// platforms, so this is computed explicitly to keep assignment reproducible.
  static int _stableHash(String value, int seed) {
    var hash = 0x811C9DC5 ^ seed;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
