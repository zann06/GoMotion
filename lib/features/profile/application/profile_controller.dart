import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/fixtures.dart';

/// Mutable demo profile: wallet balance, reward points, and saved places.
///
/// Seeded from `demo_user.json` on first load; every later change is in-memory
/// only. The user's real identity is never involved, and nothing here is
/// persisted, so relaunching restores the fixture baseline.
class ProfileController extends Notifier<DemoUser> {
  @override
  DemoUser build() {
    final bundle = ref.watch(fixtureBundleProvider).value;
    return bundle?.demoUser ?? _fallbackUser;
  }

  /// A benign placeholder used only while fixtures are still loading.
  static const DemoUser _fallbackUser = DemoUser(
    id: 'user_demo',
    displayName: 'Demo user',
    avatarAsset: 'avatar_demo.png',
    demoWalletBalance: 0,
    rewardPoints: 0,
    favoriteLocationIds: [],
  );

  /// Deducts [amount] from the fictional wallet.
  ///
  /// Returns a typed failure instead of allowing a negative balance.
  AppFailure? debitWallet(int amount) {
    if (amount > state.demoWalletBalance) {
      return InsufficientBalanceFailure(
        required: amount,
        available: state.demoWalletBalance,
      );
    }
    state = state.copyWith(demoWalletBalance: state.demoWalletBalance - amount);
    return null;
  }

  /// Credits fictional reward points, e.g. after a completed journey.
  void addPoints(int points) {
    if (points <= 0) return;
    state = state.copyWith(rewardPoints: state.rewardPoints + points);
  }

  /// Returns [amount] to the fictional wallet, e.g. when a paid demo order is
  /// cancelled before preparation begins.
  void creditWallet(int amount) {
    if (amount <= 0) return;
    state = state.copyWith(demoWalletBalance: state.demoWalletBalance + amount);
  }

  /// Toggles a saved place, keeping the list free of duplicates.
  void toggleFavorite(String locationId) {
    final current = state.favoriteLocationIds;
    final next = current.contains(locationId)
        ? [
            for (final id in current)
              if (id != locationId) id,
          ]
        : [...current, locationId];
    state = state.copyWith(favoriteLocationIds: next);
  }

  /// Spends points on a reward, returning a typed failure when unaffordable.
  AppFailure? spendPoints(int cost) {
    if (cost > state.rewardPoints) {
      return InsufficientBalanceFailure(
        required: cost,
        available: state.rewardPoints,
      );
    }
    state = state.copyWith(rewardPoints: state.rewardPoints - cost);
    return null;
  }

  /// Restores the fixture baseline for the demo profile.
  void reset() {
    final bundle = ref.read(fixtureBundleProvider).value;
    state = bundle?.demoUser ?? _fallbackUser;
  }
}

/// Provides the mutable demo profile.
final profileProvider = NotifierProvider<ProfileController, DemoUser>(
  ProfileController.new,
);

/// Provides the wallet balance in fictional rupiah.
final walletBalanceProvider = Provider<int>(
  (ref) => ref.watch(profileProvider).demoWalletBalance,
);

/// Provides the saved place ids as a lookup set.
final favoriteIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(profileProvider).favoriteLocationIds.toSet(),
);
