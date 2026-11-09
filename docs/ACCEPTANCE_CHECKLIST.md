# Acceptance Checklist

## Product and design
- [ ] GoMotion name/tagline and original mark are used consistently.
- [ ] Indigo/blue/violet palette is primary; green is semantic only.
- [ ] Screens match individual references and safe-area rules.
- [ ] Demo/fictional labels are visible wherever appropriate.

## Offline
- [ ] App launches and completes all journeys in airplane mode.
- [ ] No backend, network API, cloud database, GPS, external map, or remote image dependency.
- [ ] All assets and fixtures are bundled.

## Functionality
- [ ] Destination search and selection.
- [ ] Ride booking, matching, tracking, completion, payment, rating.
- [ ] GoFood browse/cart/checkout/tracking/receipt.
- [ ] GoSend quote/confirmation/tracking/receipt.
- [ ] Activity, profile, rewards, favorites, settings, reset.
- [ ] Every button has a working local action.

## Simulation integrity
- [ ] State transitions validated.
- [ ] Duplicate booking/payment/activity prevented.
- [ ] Cancellation and reset invalidate stale timers.
- [ ] Deterministic driver selection verified.

## Quality
- [ ] Reduced motion and accessibility labels.
- [ ] No layout overflow at supported text scaling.
- [ ] `dart format .`, `flutter analyze`, and `flutter test` pass.
- [ ] Android and iOS release build checks documented.
- [ ] README, changelog, contribution guide, and license complete.
