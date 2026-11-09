import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/entities/activity_record.dart';
import '../../../domain/entities/fixtures.dart';
import '../../../domain/entities/parcel_delivery.dart';
import '../../../domain/repositories/fixture_repository.dart';
import '../../../simulation/driver_assigner.dart';
import '../../../simulation/simulation_clock.dart';
import '../../activity/application/activity_controller.dart';
import '../../profile/application/profile_controller.dart';

/// Snapshot of the GoSend flow.
class SendState {
  const SendState({this.parcel, this.generation = 0});

  final ParcelDelivery? parcel;
  final int generation;

  bool get hasParcel => parcel != null;

  /// The current stage, defaulting to [SendStage.draft].
  SendStage get stage => parcel?.stage ?? SendStage.draft;

  @override
  bool operator ==(Object other) =>
      other is SendState &&
      other.parcel == parcel &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(parcel, generation);
}

/// Drives the simulated GoSend parcel lifecycle.
class SendController extends Notifier<SendState> {
  CancelTask? _pending;

  @override
  SendState build() {
    ref.onDispose(_cancelPending);
    return const SendState();
  }

  FixtureBundle get _bundle {
    final bundle = ref.read(fixtureBundleProvider).value;
    if (bundle == null) {
      throw StateError('Send flow requires loaded fixtures.');
    }
    return bundle;
  }

  SimulationClock get _clock => ref.read(simulationClockProvider);

  void _cancelPending() {
    _pending?.call();
    _pending = null;
  }

  int _bump() {
    _cancelPending();
    return state.generation + 1;
  }

  /// The GoSend delivery option from the fixture data.
  DeliveryOption? get _option {
    for (final option in _bundle.deliveryOptions) {
      if (option.serviceType == 'GoSend') return option;
    }
    return _bundle.deliveryOptions.isEmpty
        ? null
        : _bundle.deliveryOptions.first;
  }

  /// Creates a fresh draft, discarding any previous parcel.
  void startDraft() {
    final generation = _bump();
    state = SendState(
      generation: generation,
      parcel: ParcelDelivery(
        id: 'send_${DateTime.now().microsecondsSinceEpoch}',
        stage: SendStage.draft,
        generation: generation,
      ),
    );
  }

  /// Updates draft fields while the parcel is still editable.
  void updateDraft({
    String? senderName,
    String? senderAddress,
    String? recipientName,
    String? recipientAddress,
    PackageCategory? category,
  }) {
    final parcel = state.parcel;
    if (parcel == null) return;
    if (parcel.stage != SendStage.draft && parcel.stage != SendStage.quoted) {
      return;
    }

    state = SendState(
      generation: state.generation,
      parcel: parcel.copyWith(
        // Editing after a quote invalidates it, so drop back to draft.
        stage: SendStage.draft,
        senderName: senderName,
        senderAddress: senderAddress,
        recipientName: recipientName,
        recipientAddress: recipientAddress,
        category: category,
      ),
    );
  }

  /// Computes the quote, requiring sender, recipient, and category.
  AppFailure? requestQuote() {
    final parcel = state.parcel;
    if (parcel == null) return const NotFoundFailure(id: 'send_draft');

    if (parcel.senderName.trim().isEmpty) {
      return const ValidationFailure(
        field: 'sender_name',
        message: 'Enter a demo sender name.',
      );
    }
    if (parcel.senderAddress.trim().isEmpty) {
      return const ValidationFailure(
        field: 'sender_address',
        message: 'Enter a demo pickup address.',
      );
    }
    if (parcel.recipientName.trim().isEmpty) {
      return const ValidationFailure(
        field: 'recipient_name',
        message: 'Enter a demo recipient name.',
      );
    }
    if (parcel.recipientAddress.trim().isEmpty) {
      return const ValidationFailure(
        field: 'recipient_address',
        message: 'Enter a demo delivery address.',
      );
    }
    if (parcel.category == null) {
      return const ValidationFailure(
        field: 'package_category',
        message: 'Choose a demo package category.',
      );
    }

    final option = _option;
    if (option == null) {
      return const NotFoundFailure(id: 'delivery_option');
    }

    state = SendState(
      generation: state.generation,
      parcel: parcel.copyWith(
        stage: SendStage.quoted,
        optionId: option.id,
        baseFee: option.baseFee,
        perKmFee: option.perKmFee,
        // A deterministic simulated distance keeps the fee reproducible.
        distanceKm: _simulatedDistanceKm(parcel.id),
      ),
    );
    return null;
  }

  /// A stable simulated distance between 2 and 9 km derived from the id.
  double _simulatedDistanceKm(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return 2 + (hash % 71) / 10;
  }

  /// Confirms the quoted parcel and charges the selected method.
  AppFailure? confirm({required String paymentMethod}) {
    final parcel = state.parcel;
    if (parcel == null) return const NotFoundFailure(id: 'send_draft');
    if (parcel.stage != SendStage.quoted) {
      return InvalidTransitionFailure(
        from: parcel.stage.name,
        to: SendStage.confirmed.name,
      );
    }

    final total = parcel.total;
    if (paymentMethod == SendPayment.demoWallet) {
      final balance = ref.read(profileProvider).demoWalletBalance;
      if (balance < total) {
        return InsufficientBalanceFailure(required: total, available: balance);
      }
      ref.read(profileProvider.notifier).debitWallet(total);
    }

    final generation = _bump();
    state = SendState(
      generation: generation,
      parcel: parcel.copyWith(
        stage: SendStage.matchingCourier,
        paymentMethod: paymentMethod,
        generation: generation,
      ),
    );

    _schedule(SimulationTiming.courierMatching, () {
      _assignCourier(generation);
    });
    return null;
  }

  void _assignCourier(int generation) {
    if (state.generation != generation) return;
    final parcel = state.parcel;
    if (parcel == null || parcel.stage != SendStage.matchingCourier) return;

    final courier = DriverAssigner.assign(
      rideId: parcel.id,
      candidates: _bundle.drivers,
      seed: AppInfo.simulationSeed,
    );

    state = SendState(
      generation: generation,
      parcel: parcel.copyWith(
        stage: SendStage.courierAssigned,
        courierId: courier?.id,
      ),
    );

    _schedule(SimulationTiming.preparing, () {
      _advance(
        generation,
        from: SendStage.courierAssigned,
        to: SendStage.pickedUp,
      );
    });
  }

  void _advance(
    int generation, {
    required SendStage from,
    required SendStage to,
  }) {
    if (state.generation != generation) return;
    final parcel = state.parcel;
    if (parcel == null || parcel.stage != from) return;
    if (!isValidSendTransition(from, to)) return;

    state = SendState(
      generation: generation,
      parcel: parcel.copyWith(stage: to),
    );

    if (to == SendStage.pickedUp) {
      _schedule(SimulationTiming.inTransit, () {
        _advance(generation, from: to, to: SendStage.inTransit);
      });
    } else if (to == SendStage.inTransit) {
      _schedule(SimulationTiming.inTransit, () {
        _advance(generation, from: to, to: SendStage.delivered);
      });
    } else if (to == SendStage.delivered) {
      _finish(generation);
    }
  }

  /// Records the delivered parcel exactly once.
  void _finish(int generation) {
    if (state.generation != generation) return;
    final parcel = state.parcel;
    if (parcel == null || parcel.stage != SendStage.delivered) return;

    ref.read(profileProvider.notifier).addPoints(AppInfo.demoPointsPerJourney);

    ref
        .read(activityProvider.notifier)
        .record(
          ActivityRecord(
            journeyId: parcel.id,
            kind: ActivityKind.send,
            title: '${parcel.senderName} → ${parcel.recipientName}',
            subtitle:
                '${parcel.category?.label ?? 'Demo parcel'} · '
                '${parcel.recipientAddress}',
            amount: parcel.total,
            status: ActivityStatus.completed,
            createdAt: _clock.now(),
            paymentMethod: parcel.paymentMethod,
          ),
        );
  }

  /// Cancels through courier matching, refunding any wallet charge.
  AppFailure? cancel() {
    final parcel = state.parcel;
    if (parcel == null) return const NotFoundFailure(id: 'send_draft');
    if (!parcel.stage.isCancellable) {
      return InvalidTransitionFailure(
        from: parcel.stage.name,
        to: SendStage.draft.name,
      );
    }

    final wasCharged =
        parcel.stage == SendStage.matchingCourier &&
        parcel.paymentMethod == SendPayment.demoWallet;

    // Capture the stage before bumping; `_bump()` only cancels timers.
    final previousStage = parcel.stage;

    final generation = _bump();

    if (wasCharged) {
      ref.read(profileProvider.notifier).creditWallet(parcel.total);
    }

    // Any booked parcel leaves a cancelled record, whether or not it was
    // charged, so Activity always reflects what the user actually cancelled.
    const chargeableStages = {
      SendStage.matchingCourier,
      SendStage.courierAssigned,
    };
    if (chargeableStages.contains(previousStage)) {
      ref
          .read(activityProvider.notifier)
          .record(
            ActivityRecord(
              journeyId: parcel.id,
              kind: ActivityKind.send,
              title: '${parcel.senderName} → ${parcel.recipientName}',
              subtitle: 'Cancelled demo parcel',
              amount: 0,
              status: ActivityStatus.cancelled,
              createdAt: _clock.now(),
            ),
          );
    }

    state = SendState(generation: generation);
    return null;
  }

  /// Clears the flow without recording anything, used by reset.
  void reset() {
    _bump();
    state = SendState(generation: state.generation + 1);
  }

  void _schedule(Duration delay, void Function() callback) {
    _cancelPending();
    _pending = _clock.schedule(delay, () {
      _pending = null;
      callback();
    });
  }
}

/// Payment methods offered by the demo parcel flow.
abstract final class SendPayment {
  static const String cash = 'cash';
  static const String demoWallet = 'wallet';
}

/// Provides the GoSend flow state.
final sendProvider = NotifierProvider<SendController, SendState>(
  SendController.new,
);
