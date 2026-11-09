import 'package:flutter/foundation.dart';

/// The GoSend lifecycle from `docs/SIMULATION_ENGINE.md`:
/// `DRAFT → QUOTED → CONFIRMED → MATCHING_COURIER → COURIER_ASSIGNED →
/// PICKED_UP → IN_TRANSIT → DELIVERED → RECEIPT`.
enum SendStage {
  draft,
  quoted,
  confirmed,
  matchingCourier,
  courierAssigned,
  pickedUp,
  inTransit,
  delivered,
  receipt;

  /// Cancellation is allowed through courier matching.
  bool get isCancellable =>
      this == draft ||
      this == quoted ||
      this == confirmed ||
      this == matchingCourier;

  bool get isTerminal => this == receipt;

  bool get isLive => this == matchingCourier || this == inTransit;
}

/// Package categories offered by the demo.
enum PackageCategory {
  document('Document', 0),
  smallParcel('Small parcel', 3000),
  largeParcel('Large parcel', 8000);

  const PackageCategory(this.label, this.surcharge);

  /// Human-readable label.
  final String label;

  /// Extra fictional rupiah added to the base delivery fee.
  final int surcharge;
}

/// A GoSend parcel draft and its lifecycle state.
@immutable
class ParcelDelivery {
  const ParcelDelivery({
    required this.id,
    required this.stage,
    this.senderName = '',
    this.senderAddress = '',
    this.recipientName = '',
    this.recipientAddress = '',
    this.category,
    this.optionId,
    this.baseFee = 0,
    this.perKmFee = 0,
    this.distanceKm = 0,
    this.courierId,
    this.generation = 0,
    this.paymentMethod,
  });

  final String id;
  final SendStage stage;
  final String senderName;
  final String senderAddress;
  final String recipientName;
  final String recipientAddress;
  final PackageCategory? category;

  /// Delivery option id from `delivery_options.json`.
  final String? optionId;

  final int baseFee;
  final int perKmFee;
  final double distanceKm;
  final String? courierId;
  final int generation;
  final String? paymentMethod;

  /// Category surcharge in fictional rupiah.
  int get surcharge => category?.surcharge ?? 0;

  /// Estimated fee: base + simulated distance + category surcharge.
  int get total => baseFee + (perKmFee * distanceKm).round() + surcharge;

  /// Whether the sender, recipient, and category are all present.
  bool get isComplete =>
      senderName.trim().isNotEmpty &&
      senderAddress.trim().isNotEmpty &&
      recipientName.trim().isNotEmpty &&
      recipientAddress.trim().isNotEmpty &&
      category != null;

  ParcelDelivery copyWith({
    SendStage? stage,
    String? senderName,
    String? senderAddress,
    String? recipientName,
    String? recipientAddress,
    PackageCategory? category,
    String? optionId,
    int? baseFee,
    int? perKmFee,
    double? distanceKm,
    String? courierId,
    int? generation,
    String? paymentMethod,
  }) {
    return ParcelDelivery(
      id: id,
      stage: stage ?? this.stage,
      senderName: senderName ?? this.senderName,
      senderAddress: senderAddress ?? this.senderAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      category: category ?? this.category,
      optionId: optionId ?? this.optionId,
      baseFee: baseFee ?? this.baseFee,
      perKmFee: perKmFee ?? this.perKmFee,
      distanceKm: distanceKm ?? this.distanceKm,
      courierId: courierId ?? this.courierId,
      generation: generation ?? this.generation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ParcelDelivery &&
      other.id == id &&
      other.stage == stage &&
      other.senderName == senderName &&
      other.senderAddress == senderAddress &&
      other.recipientName == recipientName &&
      other.recipientAddress == recipientAddress &&
      other.category == category &&
      other.baseFee == baseFee &&
      other.perKmFee == perKmFee &&
      other.distanceKm == distanceKm &&
      other.courierId == courierId &&
      other.generation == generation &&
      other.paymentMethod == paymentMethod;

  @override
  int get hashCode => Object.hash(
    id,
    stage,
    senderName,
    senderAddress,
    recipientName,
    recipientAddress,
    category,
    baseFee,
    perKmFee,
    distanceKm,
    courierId,
    generation,
    paymentMethod,
  );

  @override
  String toString() => 'ParcelDelivery($id, $stage)';
}

const List<SendStage> _sendStageOrder = [
  SendStage.draft,
  SendStage.quoted,
  SendStage.confirmed,
  SendStage.matchingCourier,
  SendStage.courierAssigned,
  SendStage.pickedUp,
  SendStage.inTransit,
  SendStage.delivered,
  SendStage.receipt,
];

/// Whether [from] may legally advance to [to].
bool isValidSendTransition(SendStage from, SendStage to) {
  if (from == to) return false;
  final fromIndex = _sendStageOrder.indexOf(from);
  final toIndex = _sendStageOrder.indexOf(to);
  if (fromIndex < 0 || toIndex < 0) return false;
  return toIndex == fromIndex + 1;
}
