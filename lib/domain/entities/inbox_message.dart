import 'package:flutter/foundation.dart';

/// What a simulated inbox message is about.
///
/// The kind only drives iconography and ordering; nothing here implies a
/// server, a push service, or a real sender.
enum InboxKind {
  order('Orders'),
  promo('Promos'),
  system('System');

  const InboxKind(this.label);

  /// Human-readable label used in the filter chips and semantics.
  final String label;

  /// Parses a fixture value, defaulting to [InboxKind.system] for unknown kinds
  /// so a future fixture cannot crash an older build.
  static InboxKind fromFixture(String value) {
    for (final kind in InboxKind.values) {
      if (kind.name == value) return kind;
    }
    return InboxKind.system;
  }
}

/// One message in the simulated inbox, loaded from `notifications.json`.
@immutable
class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.read = false,
    this.actionLabel,
    this.actionRoute,
  });

  final String id;
  final InboxKind kind;
  final String title;
  final String body;

  /// Pre-rendered relative time from the fixture, e.g. `12 min ago`.
  ///
  /// Kept as a fixture string on purpose: the demo has no clock that would make
  /// a computed timestamp meaningful.
  final String timeLabel;

  /// Whether the message starts read; the controller tracks later changes.
  final bool read;

  /// Optional call to action, e.g. `Open GoFood`.
  final String? actionLabel;

  /// Route the action opens, e.g. `/food`. Absolute so the data layer stays
  /// free of navigation types.
  final String? actionRoute;

  /// True when the message can be tapped through to a destination.
  bool get hasAction =>
      actionRoute != null &&
      actionRoute!.isNotEmpty &&
      actionLabel != null &&
      actionLabel!.isNotEmpty;

  /// Returns a copy with the resolved read flag.
  InboxMessage withRead(bool value) => InboxMessage(
    id: id,
    kind: kind,
    title: title,
    body: body,
    timeLabel: timeLabel,
    read: value,
    actionLabel: actionLabel,
    actionRoute: actionRoute,
  );

  @override
  bool operator ==(Object other) =>
      other is InboxMessage && other.id == id && other.read == read;

  @override
  int get hashCode => Object.hash(id, read);

  @override
  String toString() => 'InboxMessage($id, read: $read)';
}
