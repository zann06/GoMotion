import 'package:flutter/foundation.dart';

/// The GoFood lifecycle from `docs/SIMULATION_ENGINE.md`:
/// `BROWSING → RESTAURANT_SELECTED → CART_READY → CHECKOUT →
/// MATCHING_COURIER → PREPARING → ON_THE_WAY → DELIVERED → RECEIPT`.
enum FoodStage {
  browsing,
  restaurantSelected,
  cartReady,
  checkout,
  matchingCourier,
  preparing,
  onTheWay,
  delivered,
  receipt;

  /// Cancellation is allowed before preparation begins.
  bool get isCancellable =>
      this == restaurantSelected ||
      this == cartReady ||
      this == checkout ||
      this == matchingCourier;

  bool get isTerminal => this == receipt;

  /// Whether the courier simulation should still be ticking.
  bool get isLive =>
      this == matchingCourier || this == preparing || this == onTheWay;

  /// Whether the cart contents may still be added to or changed.
  ///
  /// Once checkout is reached the order is locked: no further line edits, so a
  /// delivered or in-flight order can never be re-checked-out or re-charged.
  bool get isEditable =>
      this == browsing || this == restaurantSelected || this == cartReady;
}

/// A single cart line.
@immutable
class CartLine {
  const CartLine({
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.imageAsset,
  });

  final String itemId;
  final String name;
  final int unitPrice;
  final int quantity;
  final String imageAsset;

  /// Line total in fictional rupiah.
  int get subtotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) => CartLine(
    itemId: itemId,
    name: name,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    imageAsset: imageAsset,
  );

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.itemId == itemId &&
      other.unitPrice == unitPrice &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(itemId, unitPrice, quantity);

  @override
  String toString() => 'CartLine($itemId x$quantity)';
}

/// A GoFood cart and its lifecycle state.
@immutable
class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.stage,
    this.restaurantId,
    this.restaurantName,
    this.lines = const [],
    this.deliveryFeeId,
    this.deliveryFee = 0,
    this.courierId,
    this.generation = 0,
    this.progress = 0,
    this.paymentMethod,
  });

  final String id;
  final FoodStage stage;
  final String? restaurantId;
  final String? restaurantName;
  final List<CartLine> lines;

  /// Selected delivery option id, resolved from `delivery_options.json`.
  final String? deliveryFeeId;

  /// Delivery fee in fictional rupiah.
  final int deliveryFee;

  final String? courierId;
  final int generation;

  /// Courier progress 0..1.
  final double progress;

  final String? paymentMethod;

  /// Items subtotal.
  int get itemsTotal {
    var total = 0;
    for (final line in lines) {
      total += line.subtotal;
    }
    return total;
  }

  /// Total quantity across all lines.
  int get itemCount {
    var count = 0;
    for (final line in lines) {
      count += line.quantity;
    }
    return count;
  }

  /// Grand total including the demo delivery fee.
  int get total => itemsTotal + deliveryFee;

  /// Whether the cart has anything in it.
  bool get isEmpty => lines.isEmpty;

  /// The quantity for [itemId], or 0 when absent.
  int quantityOf(String itemId) {
    for (final line in lines) {
      if (line.itemId == itemId) return line.quantity;
    }
    return 0;
  }

  FoodOrder copyWith({
    FoodStage? stage,
    String? restaurantId,
    String? restaurantName,
    List<CartLine>? lines,
    String? deliveryFeeId,
    int? deliveryFee,
    String? courierId,
    int? generation,
    double? progress,
    String? paymentMethod,
    bool clearCourier = false,
  }) {
    return FoodOrder(
      id: id,
      stage: stage ?? this.stage,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      lines: lines ?? this.lines,
      deliveryFeeId: deliveryFeeId ?? this.deliveryFeeId,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      courierId: clearCourier ? null : (courierId ?? this.courierId),
      generation: generation ?? this.generation,
      progress: progress ?? this.progress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FoodOrder &&
      other.id == id &&
      other.stage == stage &&
      other.restaurantId == restaurantId &&
      other.deliveryFee == deliveryFee &&
      other.courierId == courierId &&
      other.generation == generation &&
      other.progress == progress &&
      listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hash(
    id,
    stage,
    restaurantId,
    deliveryFee,
    courierId,
    generation,
    progress,
    Object.hashAll(lines),
  );

  @override
  String toString() => 'FoodOrder($id, $stage, ${lines.length} lines)';
}

/// The explicit stage ordering, used to validate transitions.
const List<FoodStage> _foodStageOrder = [
  FoodStage.browsing,
  FoodStage.restaurantSelected,
  FoodStage.cartReady,
  FoodStage.checkout,
  FoodStage.matchingCourier,
  FoodStage.preparing,
  FoodStage.onTheWay,
  FoodStage.delivered,
  FoodStage.receipt,
];

/// Whether [from] may legally advance to [to].
///
/// The path is strictly sequential; cancellation and reset are handled by the
/// controller as explicit clears rather than as normal transitions.
bool isValidFoodTransition(FoodStage from, FoodStage to) {
  if (from == to) return false;
  final fromIndex = _foodStageOrder.indexOf(from);
  final toIndex = _foodStageOrder.indexOf(to);
  if (fromIndex < 0 || toIndex < 0) return false;
  return toIndex == fromIndex + 1;
}
