import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/activity_record.dart';

/// The in-memory activity ledger.
///
/// Holds at most one record per journey id. `record` is the single write path,
/// so a duplicate booking, payment retry, or double-tapped confirmation can never
/// produce two history rows for the same journey.
class ActivityController extends Notifier<List<ActivityRecord>> {
  @override
  List<ActivityRecord> build() => const [];

  /// Records [record] unless a record for the same journey already exists.
  ///
  /// Returns false when the write was rejected as a duplicate, letting callers
  /// surface the guard without throwing.
  bool record(ActivityRecord record) {
    if (state.any((r) => r.journeyId == record.journeyId)) return false;
    // Newest first keeps the list stable without sorting on every read.
    state = [record, ...state];
    return true;
  }

  /// Attaches a star rating to an existing journey record.
  void rateJourney(String journeyId, int stars) {
    state = [
      for (final record in state)
        if (record.journeyId == journeyId)
          ActivityRecord(
            journeyId: record.journeyId,
            kind: record.kind,
            title: record.title,
            subtitle: record.subtitle,
            amount: record.amount,
            status: record.status,
            createdAt: record.createdAt,
            paymentMethod: record.paymentMethod,
            rating: stars,
          )
        else
          record,
    ];
  }

  /// Looks up a record, or null when the id is unknown.
  ActivityRecord? byId(String journeyId) {
    for (final record in state) {
      if (record.journeyId == journeyId) return record;
    }
    return null;
  }

  /// Clears the ledger, used by reset simulation.
  void clear() => state = const [];
}

/// Provides the activity ledger, newest first.
final activityProvider =
    NotifierProvider<ActivityController, List<ActivityRecord>>(
      ActivityController.new,
    );

/// Provides records filtered by [kind], or all when null.
final activityFilterProvider =
    Provider.family<List<ActivityRecord>, ActivityKind?>((ref, kind) {
      final all = ref.watch(activityProvider);
      if (kind == null) return all;
      return [
        for (final r in all)
          if (r.kind == kind) r,
      ];
    });

/// Provides one activity record by journey id, or null when unknown.
final activityRecordProvider = Provider.family<ActivityRecord?, String>((
  ref,
  journeyId,
) {
  final all = ref.watch(activityProvider);
  for (final record in all) {
    if (record.journeyId == journeyId) return record;
  }
  return null;
});
