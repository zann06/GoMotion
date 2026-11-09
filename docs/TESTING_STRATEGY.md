# Testing Strategy

## Unit tests
- Fare calculations, promo eligibility, quantity rules, wallet sufficiency.
- Every valid and invalid state-machine transition.
- Duplicate booking/payment/activity protection.
- Deterministic driver assignment for a fixed seed.
- Fake-clock progression, cancellation, reset, and stale event rejection.
- Fixture schema, unique IDs, and foreign keys.

## Widget tests
- Selected/unselected vehicle cards.
- Destination search and validation.
- Cart quantity and checkout disabled state.
- Demo payment method selection and receipt labels.
- Reduced-motion behavior and semantic labels.

## Integration tests
- Complete ride journey through rating.
- Cancel during permitted matching state and verify no later progress.
- Complete GoFood order.
- Complete GoSend parcel flow.
- Reset simulation and verify restored baseline.
- Airplane-mode launch and core navigation.

## Release gates
`dart format .`, `flutter analyze`, `flutter test`, fixture validation, Android release build, and iOS release build on macOS. Capture screenshots at a standard phone viewport and inspect overflow/text scaling.
