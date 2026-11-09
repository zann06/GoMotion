import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/providers/reduced_motion_provider.dart';
import '../../activity/application/activity_controller.dart';
import '../../food/application/food_controller.dart';
import '../../profile/application/profile_controller.dart';
import '../../rewards/application/rewards_controller.dart';
import '../../ride/application/ride_controller.dart';
import '../../send/application/send_controller.dart';

/// Coordinates a full reset of the local simulation.
///
/// Every in-memory holder is cleared in one place so no feature can be left
/// behind with stale state: active journeys, activity history, rewards, the
/// demo wallet, and any pending simulation timers. Preferences are cleared too,
/// which is why the caller must confirm first.
class SimulationReset {
  const SimulationReset(this._ref);

  final Ref _ref;

  /// Clears all simulated state and returns the app to its fixture baseline.
  Future<void> run() async {
    // Cancel timers first so no scheduled callback can write after the clear.
    _ref.read(simulationClockProvider).cancelAll();

    _ref.read(rideProvider.notifier).reset();
    _ref.read(foodProvider.notifier).reset();
    _ref.read(sendProvider.notifier).reset();
    _ref.read(activityProvider.notifier).clear();
    _ref.read(rewardsProvider.notifier).reset();
    _ref.read(profileProvider.notifier).reset();

    // Restore the in-app motion override too, so no setting survives a reset.
    _ref.read(inAppReduceMotionProvider.notifier).set(false);

    await _ref.read(preferencesStoreProvider).clear();
  }
}

/// Provides the reset coordinator.
final simulationResetProvider = Provider<SimulationReset>(SimulationReset.new);
