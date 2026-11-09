import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomotion/app/providers/app_providers.dart';
import 'package:gomotion/core/constants/app_constants.dart';
import 'package:gomotion/core/errors/app_failure.dart';
import 'package:gomotion/data/preferences/preferences_store.dart';
import 'package:gomotion/domain/entities/activity_record.dart';
import 'package:gomotion/domain/entities/parcel_delivery.dart';
import 'package:gomotion/features/activity/application/activity_controller.dart';
import 'package:gomotion/features/profile/application/profile_controller.dart';
import 'package:gomotion/features/send/application/send_controller.dart';
import 'package:gomotion/simulation/fake_simulation_clock.dart';

Future<(ProviderContainer, FakeSimulationClock)> _harness() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = FakeSimulationClock();
  final container = ProviderContainer(
    overrides: [
      preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore()),
      simulationClockProvider.overrideWithValue(clock),
    ],
  );
  await container.read(fixtureBundleProvider.future);
  return (container, clock);
}

/// Fills a complete draft and returns the notifier.
SendController _completeDraft(ProviderContainer container) {
  final send = container.read(sendProvider.notifier);
  send.startDraft();
  send.updateDraft(
    senderName: 'Demo Sender',
    senderAddress: 'Jl. Fictional No. 1',
    recipientName: 'Demo Recipient',
    recipientAddress: 'Jl. Imaginary No. 2',
    category: PackageCategory.smallParcel,
  );
  return send;
}

void main() {
  group('GoSend flow', () {
    test('runs the full lifecycle to a delivered parcel', () async {
      final (container, clock) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      expect(container.read(sendProvider).stage, SendStage.draft);

      expect(send.requestQuote(), isNull);
      expect(container.read(sendProvider).stage, SendStage.quoted);
      expect(container.read(sendProvider).parcel!.total, greaterThan(0));

      expect(send.confirm(paymentMethod: SendPayment.cash), isNull);
      expect(container.read(sendProvider).stage, SendStage.matchingCourier);

      clock.advance(SimulationTiming.courierMatching);
      expect(container.read(sendProvider).stage, SendStage.courierAssigned);
      expect(container.read(sendProvider).parcel!.courierId, isNotNull);

      clock.advance(SimulationTiming.preparing);
      expect(container.read(sendProvider).stage, SendStage.pickedUp);

      clock.advance(SimulationTiming.inTransit);
      expect(container.read(sendProvider).stage, SendStage.inTransit);

      clock.advance(SimulationTiming.inTransit);
      expect(container.read(sendProvider).stage, SendStage.delivered);

      final activity = container.read(activityProvider);
      expect(activity, hasLength(1));
      expect(activity.single.kind, ActivityKind.send);
      expect(activity.single.status, ActivityStatus.completed);
    });

    test('quote is refused until every required field is present', () async {
      final (container, _) = await _harness();
      addTearDown(container.dispose);

      final send = container.read(sendProvider.notifier);
      send.startDraft();

      // Nothing filled in.
      expect(send.requestQuote()!.code, 'validation_sender_name');

      send.updateDraft(senderName: 'Demo Sender');
      expect(send.requestQuote()!.code, 'validation_sender_address');

      send.updateDraft(senderAddress: 'Jl. Fictional No. 1');
      expect(send.requestQuote()!.code, 'validation_recipient_name');

      send.updateDraft(recipientName: 'Demo Recipient');
      expect(send.requestQuote()!.code, 'validation_recipient_address');

      send.updateDraft(recipientAddress: 'Jl. Imaginary No. 2');
      expect(send.requestQuote()!.code, 'validation_package_category');

      send.updateDraft(category: PackageCategory.document);
      expect(send.requestQuote(), isNull);
      expect(container.read(sendProvider).stage, SendStage.quoted);
    });

    test('whitespace-only input is treated as missing', () async {
      final (container, _) = await _harness();
      addTearDown(container.dispose);

      final send = container.read(sendProvider.notifier);
      send.startDraft();
      send.updateDraft(
        senderName: '   ',
        senderAddress: '  ',
        recipientName: '\t',
        recipientAddress: '',
        category: PackageCategory.document,
      );

      expect(send.requestQuote(), isNotNull);
      expect(container.read(sendProvider).stage, SendStage.draft);
    });

    test('editing after a quote invalidates it', () async {
      final (container, _) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      expect(send.requestQuote(), isNull);
      expect(container.read(sendProvider).stage, SendStage.quoted);

      send.updateDraft(recipientName: 'Another Demo Recipient');
      expect(container.read(sendProvider).stage, SendStage.draft);

      // A stale quote can no longer be confirmed.
      final failure = send.confirm(paymentMethod: SendPayment.cash);
      expect(failure, isA<InvalidTransitionFailure>());
      expect(failure!.code, 'invalid_transition');
    });

    test('confirming charges the demo wallet once', () async {
      final (container, _) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      send.requestQuote();

      final before = container.read(profileProvider).demoWalletBalance;
      final total = container.read(sendProvider).parcel!.total;

      expect(send.confirm(paymentMethod: SendPayment.demoWallet), isNull);
      expect(container.read(profileProvider).demoWalletBalance, before - total);

      // A second confirmation must not charge again.
      final duplicate = send.confirm(paymentMethod: SendPayment.demoWallet);
      expect(duplicate, isNotNull);
      expect(container.read(profileProvider).demoWalletBalance, before - total);
    });

    test('wallet confirmation fails when the balance is too low', () async {
      final (container, _) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      send.requestQuote();

      container
          .read(profileProvider.notifier)
          .debitWallet(container.read(profileProvider).demoWalletBalance);

      final failure = send.confirm(paymentMethod: SendPayment.demoWallet);
      expect(failure, isNotNull);
      expect(failure!.code, 'insufficient_balance');
      expect(container.read(sendProvider).stage, SendStage.quoted);
      expect(container.read(activityProvider), isEmpty);
    });

    test(
      'cancelling while matching refunds the wallet and records once',
      () async {
        final (container, clock) = await _harness();
        addTearDown(container.dispose);

        final send = _completeDraft(container);
        send.requestQuote();

        final before = container.read(profileProvider).demoWalletBalance;
        send.confirm(paymentMethod: SendPayment.demoWallet);

        expect(send.cancel(), isNull);
        expect(container.read(profileProvider).demoWalletBalance, before);
        expect(container.read(sendProvider).parcel, isNull);
        expect(clock.pendingCount, 0);

        final activity = container.read(activityProvider);
        expect(activity, hasLength(1));
        expect(activity.single.status, ActivityStatus.cancelled);
        expect(activity.single.amount, 0);
      },
    );

    test('cancelling after pickup is refused', () async {
      final (container, clock) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      send.requestQuote();
      send.confirm(paymentMethod: SendPayment.cash);

      clock.advance(SimulationTiming.courierMatching);
      clock.advance(SimulationTiming.preparing);
      expect(container.read(sendProvider).stage, SendStage.pickedUp);

      final failure = send.cancel();
      expect(failure, isNotNull);
      expect(container.read(sendProvider).stage, SendStage.pickedUp);
    });

    test('a stale timer cannot revive a cancelled parcel', () async {
      final (container, clock) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      send.requestQuote();
      send.confirm(paymentMethod: SendPayment.cash);
      send.cancel();

      clock.advance(const Duration(minutes: 10));

      expect(container.read(sendProvider).parcel, isNull);
      expect(container.read(activityProvider), hasLength(1));
    });

    test('reset clears state and leaves no pending timers', () async {
      final (container, clock) = await _harness();
      addTearDown(container.dispose);

      final send = _completeDraft(container);
      send.requestQuote();
      send.confirm(paymentMethod: SendPayment.cash);

      send.reset();
      expect(container.read(sendProvider).parcel, isNull);
      expect(clock.pendingCount, 0);

      clock.advance(const Duration(minutes: 10));
      expect(container.read(activityProvider), isEmpty);
    });
  });
}
