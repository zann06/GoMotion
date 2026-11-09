import 'package:flutter/foundation.dart';

/// The kind of simulated journey that produced an activity record.
enum ActivityKind {
  ride('Ride'),
  food('Food order'),
  send('Parcel');

  const ActivityKind(this.label);

  /// Human-readable label shown in lists and filters.
  final String label;
}

/// A single completed or cancelled simulated journey.
///
/// `docs/SIMULATION_ENGINE.md` requires exactly one activity record per terminal
/// journey, so [journeyId] is the natural uniqueness key.
@immutable
class ActivityRecord {
  const ActivityRecord({
    required this.journeyId,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.rating,
  });

  /// The ride / order / parcel id this record describes.
  final String journeyId;

  final ActivityKind kind;

  /// Primary line, e.g. "Campus Hub → Central Plaza".
  final String title;

  /// Supporting line, e.g. the driver or restaurant name.
  final String subtitle;

  /// Settled amount in fictional rupiah. Zero for cancellations.
  final int amount;

  /// Either `completed` or `cancelled`.
  final ActivityStatus status;

  /// Simulation timestamp, used for ordering.
  final DateTime createdAt;

  /// How the journey was paid, when completed.
  final String? paymentMethod;

  /// Star rating the user submitted, when rated.
  final int? rating;

  @override
  bool operator ==(Object other) =>
      other is ActivityRecord &&
      other.journeyId == journeyId &&
      other.kind == kind &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.amount == amount &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.paymentMethod == paymentMethod &&
      other.rating == rating;

  @override
  int get hashCode => Object.hash(
    journeyId,
    kind,
    title,
    subtitle,
    amount,
    status,
    createdAt,
    paymentMethod,
    rating,
  );

  @override
  String toString() => 'ActivityRecord($journeyId, $kind, $status)';
}

/// Terminal outcome of a journey.
enum ActivityStatus {
  completed('Completed'),
  cancelled('Cancelled');

  const ActivityStatus(this.label);

  final String label;
}
