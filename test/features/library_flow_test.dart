import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/app/providers/reduced_motion_provider.dart';
import 'package:gomotion/core/errors/app_failure.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/domain/entities/activity_record.dart';
import 'package:gomotion/domain/entities/parcel_delivery.dart';
import 'package:gomotion/domain/repositories/fixture_repository.dart';
import 'package:gomotion/features/activity/application/activity_controller.dart';
import 'package:gomotion/features/profile/application/profile_controller.dart';
import 'package:gomotion/features/rewards/application/rewards_controller.dart';
import 'package:gomotion/features/send/application/send_controller.dart';
import 'package:gomotion/features/settings/application/simulation_reset.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

Future<(ProviderContainer, FakeSimulationClock, FixtureBundle)>
_harness() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      simulationClockProvider.overrideWithValue(FakeSimulationClock()),
    ],
  );
  final bundle = await container.read(fixtureBundleProvider.future);
  return (
    container,
    container.read(simulationClockProvider) as FakeSimulationClock,
    bundle,
  );
}

ActivityRecord _record({
  required String id,
  ActivityKind kind = ActivityKind.ride,
  ActivityStatus status = ActivityStatus.completed,
  int amount = 25000,
}) {
  return ActivityRecord(
    journeyId: id,
    kind: kind,
    title: 'Demo A → Demo B',
    subtitle: 'Demo subtitle',
    amount: amount,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1, 10),
    paymentMethod: 'cash',
  );
}

void main() {
  group('Activity history', () {
    test('filters by kind and keeps the full ledger intact', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final ledger = container.read(activityProvider.notifier);
      ledger.record(_record(id: 'r1'));
      ledger.record(_record(id: 'f1', kind: ActivityKind.food));
      ledger.record(_record(id: 's1', kind: ActivityKind.send));

      expect(container.read(activityProvider), hasLength(3));
      expect(container.read(activityFilterProvider(null)), hasLength(3));
      expect(
        container
            .read(activityFilterProvider(ActivityKind.food))
            .single
            .journeyId,
        'f1',
      );
      expect(
        container
            .read(activityFilterProvider(ActivityKind.ride))
            .single
            .journeyId,
        'r1',
      );
    });

    test('resolves a record by id and returns null when unknown', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      container.read(activityProvider.notifier).record(_record(id: 'known'));

      expect(
        container.read(activityRecordProvider('known'))?.journeyId,
        'known',
      );
      expect(container.read(activityRecordProvider('missing')), isNull);
    });

    test('newest records come first', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final ledger = container.read(activityProvider.notifier);
      ledger.record(_record(id: 'first'));
      ledger.record(_record(id: 'second'));

      expect(container.read(activityProvider).map((r) => r.journeyId), [
        'second',
        'first',
      ]);
    });

    test('clear empties the ledger', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final ledger = container.read(activityProvider.notifier);
      ledger.record(_record(id: 'r1'));
      ledger.clear();

      expect(container.read(activityProvider), isEmpty);
    });
  });

  group('Demo profile', () {
    test('wallet debit is refused rather than going negative', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final profile = container.read(profileProvider.notifier);
      final original = container.read(profileProvider).demoWalletBalance;

      final failure = profile.debitWallet(original + 1);
      expect(failure, isA<InsufficientBalanceFailure>());
      expect(container.read(profileProvider).demoWalletBalance, original);

      expect(profile.debitWallet(original), isNull);
      expect(container.read(profileProvider).demoWalletBalance, 0);
    });

    test('credit restores a refunded amount', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final profile = container.read(profileProvider.notifier);
      final original = container.read(profileProvider).demoWalletBalance;

      profile.debitWallet(10000);
      profile.creditWallet(10000);
      expect(container.read(profileProvider).demoWalletBalance, original);

      // Non-positive credits are ignored so no phantom balance appears.
      profile.creditWallet(0);
      profile.creditWallet(-500);
      expect(container.read(profileProvider).demoWalletBalance, original);
    });

    test('favourites toggle without duplicates', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final profile = container.read(profileProvider.notifier);
      final id = bundle.locations.first.id;

      // The fixture already includes two saved places.
      if (container.read(favoriteIdsProvider).contains(id)) {
        profile.toggleFavorite(id);
      }

      expect(container.read(favoriteIdsProvider).contains(id), isFalse);
      profile.toggleFavorite(id);
      profile.toggleFavorite(id);
      expect(container.read(favoriteIdsProvider).contains(id), isFalse);

      profile.toggleFavorite(id);
      expect(
        container
            .read(profileProvider)
            .favoriteLocationIds
            .where((e) => e == id)
            .length,
        1,
      );
    });
  });

  group('Rewards', () {
    test('redeeming spends demo points once and is not repeatable', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final paid = bundle.rewards.firstWhere((r) => r.pointsCost > 0);
      final pointsBefore = container.read(profileProvider).rewardPoints;
      final rewards = container.read(rewardsProvider.notifier);

      expect(
        pointsBefore >= paid.pointsCost,
        isTrue,
        reason: 'The fixture must start with enough demo points.',
      );

      expect(rewards.redeem(paid), isNull);
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore - paid.pointsCost,
      );
      expect(container.read(rewardsProvider).contains(paid.id), isTrue);

      // A second redemption is refused and must not charge again.
      final duplicate = rewards.redeem(paid);
      expect(duplicate, isA<DuplicateActionFailure>());
      expect(
        container.read(profileProvider).rewardPoints,
        pointsBefore - paid.pointsCost,
      );
    });

    test('an unaffordable reward is refused without spending', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final profile = container.read(profileProvider.notifier);
      // Drain the wallet of points.
      profile.spendPoints(container.read(profileProvider).rewardPoints);

      final paid = bundle.rewards.firstWhere((r) => r.pointsCost > 0);
      final failure = container.read(rewardsProvider.notifier).redeem(paid);

      expect(failure, isA<InsufficientBalanceFailure>());
      expect(container.read(profileProvider).rewardPoints, 0);
      expect(container.read(rewardsProvider).contains(paid.id), isFalse);
    });

    test('free fixture rewards start unlocked', () async {
      final (container, _, bundle) = await _harness();
      addTearDown(container.dispose);

      final free = [
        for (final reward in bundle.rewards)
          if (reward.pointsCost == 0 && reward.unlocked) reward,
      ];
      expect(free, isNotEmpty);

      for (final reward in free) {
        expect(container.read(rewardsProvider).contains(reward.id), isTrue);
      }
    });
  });

  group('Simulation reset', () {
    test('clears journeys, activity, rewards, and the demo wallet', () async {
      final (container, clock, bundle) = await _harness();
      addTearDown(container.dispose);

      // Build up some state across several features.
      container.read(activityProvider.notifier).record(_record(id: 'r1'));
      container.read(profileProvider.notifier).debitWallet(50000);
      final paid = bundle.rewards.firstWhere((r) => r.pointsCost > 0);
      container.read(rewardsProvider.notifier).redeem(paid);
      container
          .read(profileProvider.notifier)
          .toggleFavorite(bundle.locations.last.id);

      final send = container.read(sendProvider.notifier);
      send.startDraft();
      send.updateDraft(
        senderName: 'Demo Sender',
        senderAddress: 'Demo pickup',
        recipientName: 'Demo Recipient',
        recipientAddress: 'Demo drop',
        category: PackageCategory.document,
      );
      send.requestQuote();
      send.confirm(paymentMethod: SendPayment.cash);
      expect(clock.pendingCount, greaterThan(0));

      await container.read(simulationResetProvider).run();

      expect(container.read(activityProvider), isEmpty);
      expect(container.read(sendProvider).parcel, isNull);
      expect(clock.pendingCount, 0);
      // Fixture baseline restored.
      expect(
        container.read(profileProvider).demoWalletBalance,
        bundle.demoUser.demoWalletBalance,
      );
      expect(
        container.read(profileProvider).rewardPoints,
        bundle.demoUser.rewardPoints,
      );
      expect(
        container.read(profileProvider).favoriteLocationIds,
        bundle.demoUser.favoriteLocationIds,
      );
      expect(container.read(rewardsProvider), {
        for (final reward in bundle.rewards)
          if (reward.unlocked) reward.id,
      });
    });

    test('reset clears the onboarding preference', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      final prefs = container.read(preferencesStoreProvider);
      await prefs.setHasSeenOnboarding(true);
      expect(prefs.hasSeenOnboarding, isTrue);

      await container.read(simulationResetProvider).run();
      expect(prefs.hasSeenOnboarding, isFalse);
    });

    test('reset clears the in-app reduced-motion override', () async {
      final (container, _, _) = await _harness();
      addTearDown(container.dispose);

      container.read(inAppReduceMotionProvider.notifier).set(true);
      expect(container.read(inAppReduceMotionProvider), isTrue);

      await container.read(simulationResetProvider).run();
      expect(container.read(inAppReduceMotionProvider), isFalse);
    });
  });
}
