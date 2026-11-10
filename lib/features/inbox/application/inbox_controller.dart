import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../domain/entities/inbox_message.dart';

/// The inbox as the UI sees it: the seeded fixture messages with the local
/// read state applied on top.
///
/// The demo has no server, so "read" lives in memory for the session. Seeding
/// from the bundle keeps the list honest: every message is authored in
/// `notifications.json`, never fetched.
class InboxState {
  const InboxState({required this.messages, this.filter});

  /// All seeded messages, fixture order preserved.
  final List<InboxMessage> messages;

  /// Active kind filter, or null for "All".
  final InboxKind? filter;

  /// Messages matching the active filter.
  List<InboxMessage> get visible => filter == null
      ? messages
      : [
          for (final message in messages)
            if (message.kind == filter) message,
        ];

  /// How many messages are still unread across the whole inbox.
  ///
  /// Deliberately ignores [filter]: the tab badge reports the real unread count,
  /// not the count within a filter the user happens to be looking at.
  int get unreadCount => messages.where((m) => !m.read).length;

  /// True when the fixture itself carries no messages.
  bool get isEmpty => messages.isEmpty;

  /// Returns a copy with a different filter.
  InboxState withFilter(InboxKind? value) =>
      InboxState(messages: messages, filter: value);
}

/// Owns the inbox read state.
///
/// Read flags are tracked as an override set rather than by mutating the
/// fixture, so a reload of the bundle cannot resurrect a message the user has
/// already dismissed as read.
class InboxController extends Notifier<InboxState> {
  /// Ids marked read during this session. Kept outside `state` so it survives a
  /// rebuild of the provider (which happens when the bundle re-resolves).
  final Set<String> _readThisSession = <String>{};

  InboxKind? _filter;

  @override
  InboxState build() {
    final bundle = ref.watch(fixtureBundleProvider).value;
    if (bundle == null) {
      return const InboxState(messages: []);
    }
    return InboxState(
      messages: [
        for (final message in bundle.notifications)
          message.withRead(
            message.read || _readThisSession.contains(message.id),
          ),
      ],
      filter: _filter,
    );
  }

  /// Applies a filter to the visible list.
  void setFilter(InboxKind? value) {
    _filter = value;
    state = state.withFilter(value);
  }

  /// Marks one message read. No-op when it is already read or unknown.
  void markRead(String id) {
    if (!state.messages.any((m) => m.id == id && !m.read)) return;
    _readThisSession.add(id);
    state = InboxState(
      messages: [
        for (final message in state.messages)
          message.id == id ? message.withRead(true) : message,
      ],
      filter: state.filter,
    );
  }

  /// Marks every message read, which also clears the tab badge.
  void markAllRead() {
    if (state.unreadCount == 0) return;
    _readThisSession.addAll(
      state.messages.where((m) => !m.read).map((m) => m.id),
    );
    state = InboxState(
      messages: [for (final m in state.messages) m.withRead(true)],
      filter: state.filter,
    );
  }
}

/// The inbox state used by both the tab badge and the inbox screen.
final inboxProvider = NotifierProvider<InboxController, InboxState>(
  InboxController.new,
);

/// Unread count for the bottom navigation badge.
///
/// Separate provider so the shell rebuilds on the count only, not on every
/// filter change inside the inbox.
final inboxUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).unreadCount;
});
