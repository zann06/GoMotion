# Acceptance Checklist

> Status markers: `[x]` verified, `[ ]` outstanding. Every item below was
> checked against the implementation in this repository. Items that depend on
> hardware or macOS tooling are marked with the verification method used.

## Foundation (Phase 0) — complete
- [x] Flutter application scaffold for Android and iOS with pinned dependencies.
- [x] Feature-first Clean Architecture folder structure.
- [x] All nine JSON fixtures parse and pass referential-integrity validation.
- [x] Malformed fixtures raise a typed `FixtureFailure` rather than defaulting
      (covered by dedicated strictness tests).
- [x] Design tokens, light theme, and brand palette established.
- [x] Deterministic simulation clock and seeded driver assigner.
- [x] `dart format .`, `flutter analyze`, and `flutter test` pass (123 tests).
- [x] CI workflow runs format, analyze, and test on push and pull request.
- [x] Release manifest declares no `INTERNET` or location permission; only the
      debug overlay adds `INTERNET`, for the Flutter hot-reload tooling
      (verified in the built release APK).

## Product and design
- [x] GoMotion name/tagline and original mark are used consistently.
- [x] Indigo/blue/violet palette is primary; green is semantic success and map
      detail only.
- [x] Screens follow the shared page scaffold, safe-area rules, and sticky
      primary actions.
- [x] Demo/fictional labels are visible wherever money, people, or services are
      shown, including fares, wallet, drivers, restaurants, parcels, and receipts.

## Offline
- [x] App launches and completes all journeys without any network access. The
      runtime has no HTTP client, and the release manifest has no `INTERNET`
      permission, so the OS would block it even if one existed.
- [x] No backend, network API, cloud database, GPS, external map, or remote
      image dependency.
- [x] All images, icons, and fixtures are bundled in `assets/`.

## Functionality
- [x] Destination search and selection (local filter, categories, recent, saved).
- [x] Ride booking, matching, tracking, completion, payment, and rating.
- [x] GoFood browse → menu → cart → checkout → tracking → receipt.
- [x] GoSend form → quote review → courier → transit → receipt.
- [x] Activity list with kind filters and per-record detail.
- [x] Profile, demo wallet, points, saved places, rewards, settings, and reset.
- [x] First-launch onboarding, shown once and persisted locally.
- [x] Every visible button has a working local action. Journey widget tests tap
      the real controls, and a grep finds no empty handlers.

## Simulation integrity
- [x] State transitions validated in domain/application layers, not widgets.
- [x] One active ride, food order, and parcel delivery at a time.
- [x] Duplicate booking and duplicate payment are refused.
- [x] Cancellation and reset invalidate generation tokens and pending timers.
- [x] Deterministic driver selection verified
      (`test/simulation/simulation_test.dart`).

## Quality
- [x] Reduced motion honoured by radar, skeletons, press scaling, and entrance
      motion; also persisted across launches.
- [x] Semantic labels on icon-only controls, live regions on async status, and
      48dp minimum touch targets.
- [x] Status is never conveyed by colour alone; every pill carries a text label.
- [x] No layout overflow at 1.0x and 1.3x text scale across all primary routes
      (`test/app/accessibility_test.dart`).
- [x] `dart format .`, `flutter analyze`, and `flutter test` pass.
- [x] Android debug and release builds succeed locally; the release APK is
      debug-signed (not suitable for store distribution).
- [ ] iOS release build — **not verified here**: requires macOS and Xcode, and
      this environment is Windows. Run `flutter build ipa --release` on a
      macOS/CI runner before shipping iOS.
- [x] README, changelog, contribution guide, and license complete.

## Release notes
- Version `0.1.0+1`, an original fictional simulation. It is not a real
  transportation, delivery, or payment service.
- The Android release APK is debug-signed; sign with a real keystore before
  distribution on any store.