# Acceptance Checklist

> Status markers: `[x]` verified, `[ ]` outstanding. Only Phase 0 and the Phase 1
> foundation are implemented so far; everything below the foundation line
> remains outstanding and must not be reported as done.

## Foundation (Phase 0) — complete
- [x] Flutter application scaffold for Android and iOS with pinned dependencies.
- [x] Feature-first Clean Architecture folder structure.
- [x] All nine JSON fixtures parse and pass referential-integrity validation.
- [x] Malformed fixtures raise a typed `FixtureFailure` rather than defaulting
      (covered by dedicated strictness tests).
- [x] Design tokens, light theme, and brand palette established.
- [x] Deterministic simulation clock and seeded driver assigner.
- [x] `dart format .`, `flutter analyze`, and `flutter test` pass (45 tests).
- [x] CI workflow runs format, analyze, and test on push and pull request.
- [x] Release manifest declares no `INTERNET` or location permission; only the
      debug overlay adds `INTERNET`, for the Flutter hot-reload tooling.

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
- [x] Deterministic driver selection verified (`test/simulation/simulation_test.dart`).

## Quality
- [ ] Reduced motion and accessibility labels.
- [ ] No layout overflow at supported text scaling.
- [ ] `dart format .`, `flutter analyze`, and `flutter test` pass.
- [ ] Android and iOS release build checks documented.
- [ ] README, changelog, contribution guide, and license complete.
