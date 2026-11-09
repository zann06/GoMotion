import 'package:flutter/foundation.dart';

/// A domain-level failure with a stable code and a user-safe message.
///
/// Domain rules return these instead of throwing, and instead of silently
/// mutating state. `docs/SIMULATION_ENGINE.md` requires typed failures for
/// invalid transitions.
@immutable
sealed class AppFailure implements Exception {
  const AppFailure({required this.code, required this.message});

  /// Stable machine-readable identifier, safe to assert on in tests.
  final String code;

  /// User-facing, actionable text. Never contains stack traces or fixture paths.
  final String message;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Invalid or forbidden lifecycle transition.
final class InvalidTransitionFailure extends AppFailure {
  const InvalidTransitionFailure({required this.from, required this.to})
    : super(
        code: 'invalid_transition',
        message:
            'That action is not available right now. Return to the previous '
            'step and try again.',
      );

  /// The state the workflow was in.
  final String from;

  /// The state the caller attempted to reach.
  final String to;
}

/// A second booking, payment, or activity record was attempted.
final class DuplicateActionFailure extends AppFailure {
  const DuplicateActionFailure({required super.code})
    : super(
        message:
            'That action was already completed for this demo journey, so it '
            'was not repeated.',
      );

  /// Duplicate guard for a second booking confirmation.
  const DuplicateActionFailure.booking() : this(code: 'duplicate_booking');

  /// Duplicate guard for a second payment on the same journey.
  const DuplicateActionFailure.payment() : this(code: 'duplicate_payment');

  /// Duplicate guard for a second activity record for one journey.
  const DuplicateActionFailure.activity() : this(code: 'duplicate_activity');
}

/// The demo wallet balance cannot cover the amount.
final class InsufficientBalanceFailure extends AppFailure {
  const InsufficientBalanceFailure({
    required this.required,
    required this.available,
  }) : super(
         code: 'insufficient_balance',
         message:
             'Your fictional demo wallet balance is too low for this payment. '
             'Choose cash, or reset the simulation to restore the demo wallet.',
       );

  final int required;
  final int available;
}

/// A promo code could not be applied.
final class InvalidPromoFailure extends AppFailure {
  const InvalidPromoFailure({required super.code, required super.message});

  const InvalidPromoFailure.notFound()
    : this(
        code: 'promo_not_found',
        message: 'That demo promo code does not exist. Try MOVE10 or FIRST5.',
      );

  const InvalidPromoFailure.inactive()
    : this(
        code: 'promo_inactive',
        message: 'That demo promo is no longer active.',
      );

  const InvalidPromoFailure.minimumNotMet()
    : this(
        code: 'promo_minimum',
        message: 'This demo fare is below the promo minimum spend.',
      );

  const InvalidPromoFailure.alreadyApplied()
    : this(
        code: 'promo_already_applied',
        message: 'A demo promo is already applied to this journey.',
      );
}

/// A required form field is missing or invalid.
final class ValidationFailure extends AppFailure {
  const ValidationFailure({required this.field, required super.message})
    : super(code: 'validation_$field');

  /// Name of the offending field, for inline display.
  final String field;
}

/// Fixture data could not be loaded or failed integrity validation.
final class FixtureFailure extends AppFailure {
  const FixtureFailure({required this.asset, this.cause})
    : super(
        code: 'fixture_invalid',
        message:
            'Bundled demo data could not be loaded. Reinstall the app to '
            'restore the offline dataset.',
      );

  /// The fixture asset key that failed.
  final String asset;

  /// Developer-facing cause. Surfaced in debug logs only.
  final String? cause;
}

/// A route was opened with a stale or unknown identifier.
final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({required this.id})
    : super(
        code: 'not_found',
        message: 'This demo item is no longer available.',
      );

  final String id;
}
