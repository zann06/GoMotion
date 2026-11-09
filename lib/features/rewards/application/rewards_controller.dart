import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/fixtures.dart';
import '../../profile/application/profile_controller.dart';

/// The in-memory rewards ledger.
///
/// Tracks which demo rewards have been unlocked this session. The fixture
/// `unlocked` flag seeds the initial set, and points are spent through
/// [ProfileController.spendPoints] so the balance rules live in one place.
class RewardsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final bundle = ref.watch(fixtureBundleProvider).value;
    if (bundle == null) return <String>{};
    return {
      for (final reward in bundle.rewards)
        if (reward.unlocked) reward.id,
    };
  }

  /// Whether [reward] has been unlocked in this session.
  bool isUnlocked(Reward reward) => state.contains(reward.id);

  /// Redeems [reward], returning a typed failure when the points are short.
  ///
  /// Redeeming is idempotent: an already-unlocked reward is not charged twice.
  AppFailure? redeem(Reward reward) {
    if (state.contains(reward.id)) {
      return const DuplicateActionFailure.activity();
    }

    if (reward.pointsCost > 0) {
      final failure = ref
          .read(profileProvider.notifier)
          .spendPoints(reward.pointsCost);
      if (failure != null) return failure;
    }

    state = {...state, reward.id};
    return null;
  }

  /// Restores the fixture unlock states, used by reset simulation.
  void reset() {
    final bundle = ref.read(fixtureBundleProvider).value;
    state = bundle == null
        ? <String>{}
        : {
            for (final reward in bundle.rewards)
              if (reward.unlocked) reward.id,
          };
  }
}

/// Provides the unlocked demo reward ids.
final rewardsProvider = NotifierProvider<RewardsController, Set<String>>(
  RewardsController.new,
);

/// Provides the reward catalogue from the fixtures.
final rewardCatalogueProvider = Provider<List<Reward>>((ref) {
  final bundle = ref.watch(fixtureBundleProvider).value;
  return bundle?.rewards ?? const [];
});
