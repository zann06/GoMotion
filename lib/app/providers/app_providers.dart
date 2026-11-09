import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/preferences/preferences_store.dart';
import '../../data/repositories/json_fixture_repository.dart';
import '../../domain/repositories/fixture_repository.dart';
import '../../simulation/simulation_clock.dart';

/// Provides the preferences store.
///
/// Overridden at bootstrap with a loaded [SharedPreferencesStore], and in tests
/// with [InMemoryPreferencesStore].
final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  throw UnimplementedError(
    'preferencesStoreProvider must be overridden at app bootstrap.',
  );
});

/// Provides the fixture repository. Overridable for tests.
final fixtureRepositoryProvider = Provider<FixtureRepository>((ref) {
  return JsonFixtureRepository();
});

/// Provides the simulation clock. Tests override with a fake clock.
final simulationClockProvider = Provider<SimulationClock>((ref) {
  final clock = RealSimulationClock();
  ref.onDispose(clock.cancelAll);
  return clock;
});

/// Asynchronously loads the validated fixture bundle once at startup.
///
/// The app shell renders a loading state until this resolves, then a
/// recoverable error state if integrity validation failed.
final fixtureBundleProvider = FutureProvider<FixtureBundle>((ref) async {
  final repository = ref.watch(fixtureRepositoryProvider);
  return repository.load();
});
