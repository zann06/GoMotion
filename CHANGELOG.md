# Changelog

All notable changes to GoMotion will be documented here.

## [0.1.0] - 2026-11-09

First complete offline release: all ten roadmap phases in
`docs/IMPLEMENTATION_PLAN.md` are implemented and the demo journeys run end to
end without a network connection.

### Added — Phase 0 (Flutter foundation)
- Flutter application scaffold targeting Android and iOS, with pinned
  dependencies: `flutter_riverpod`, `go_router`, `flutter_animate`,
  `shared_preferences`.
- Feature-first + Clean Architecture folder structure (`lib/app`, `lib/core`,
  `lib/data`, `lib/domain`, `lib/features`, `lib/simulation`).
- Strict offline fixture loader that parses and validates all nine bundled JSON
  fixtures, enforcing referential integrity per `docs/DATA_MODEL.md`. Malformed
  data raises a typed `FixtureFailure` instead of silently defaulting.
- Design tokens (colour, spacing, typography, constants) and the light theme,
  with green restricted to semantic success and map detail.
- Domain layer: fixture entities, fare engine, deterministic route geometry, and
  the `FixtureRepository` contract.
- Simulation layer: injected `SimulationClock`, `FakeSimulationClock` for
  deterministic tests, and a seeded `DriverAssigner`.
- CI workflow (`.github/workflows/flutter-ci.yml`) running format, analyze, and
  test on push and pull request.
- Test suites covering fixture parsing/integrity and strictness, fare and promo
  rules, the simulation clock, driver assignment, and app boot.

### Added — Phase 1 (design system and shell)
- GoRouter route table with a persistent four-tab shell (Home, Activity,
  Rewards, Profile) and nested flow routes with real back behaviour.
- Core widget library: page scaffold with sticky footer, cards, status pills,
  primary/tonal buttons, labelled inputs, quantity stepper, empty/loading/error
  states, schematic demo map, brand mark, and fixture gate.
- Reduced-motion providers honouring both the platform setting and an in-app
  override persisted through `shared_preferences`.
- Accessibility baseline: semantic labels on icon-only controls, 48dp minimum
  touch targets, and status conveyed by text as well as colour.

### Added — Phase 2 (home and destinations)
- Home screen with a gradient journey card, demo schematic map, service
  shortcuts, recent destinations, saved places, and a demo promo banner.
- Destination search with live local filtering, category chips, recent and
  saved sections, and an honest empty state.

### Added — Phase 3 (vehicle selection and booking)
- Vehicle comparison for the fictional GoRide, GoCar, and GoCar Premium
  services, defaulting to the cheapest option.
- Deterministic fare estimates and promo codes (`MOVE10`, `FIRST5`) with inline
  validation, removable discounts, and a duplicate-booking guard.

### Added — Phase 4 (matching and tracking)
- Animated driver-matching radar with a static reduced-motion alternative.
- Seeded driver assignment, driver card reveal, pickup confirmation, animated
  trip progress, ETA, and guarded cancellation.

### Added — Phase 5 (payment and activity)
- Demo cash and wallet payment with insufficient-balance protection and atomic
  single payment.
- Simulated receipt with rating, plus a real activity ledger with kind filters
  and per-record detail screens.

### Added — Phase 6 (GoFood)
- Restaurant browsing with category filters, menu detail, cart with quantity
  controls, checkout, courier tracking, and a receipt.
- Wallet charging at order placement and refunds on cancellation before the
  kitchen starts preparing.

### Added — Phase 7 (GoSend)
- Sender and recipient form with inline validation, package category selection,
  fare quote review, courier pickup, transit, and a delivery receipt.

### Added — Phase 8 (profile and rewards)
- Profile with the fictional wallet, demo points, saved places, and settings
  links.
- Saved places toggle screen, rewards catalogue with redeem/unlock and
  confirmation, settings (motion, simulation statistics, confirmed reset), and
  an About screen.
- `SimulationReset` coordinator that cancels timers and restores every
  controller to the fixture baseline.
- First-launch onboarding at `/welcome` explaining the offline simulation.

### Added — Phase 9 (animation polish and QA)
- Reduced-motion coverage for every decorative loop: radar, shimmer skeletons,
  press scaling, and entrance animations.
- Haptic reinforcement on primary confirmations and tab changes.
- Layout robustness: sticky footers size to content, cards provide a Material
  surface for ink and `ListTile`, and wide rows wrap instead of overflowing.
- Accessibility and layout suites render every primary route at 1.0x and 1.3x
  text scale with reduced motion enabled.

### Added — Phase 10 (production builds and documentation)
- Release build verification for Android, including a manifest check that the
  release package declares no `INTERNET` or location permission.
- Original launcher icon (indigo→blue gradient with the brand ring-chevron
  mark) across all Android densities and iOS icon slots, plus an adaptive icon
  (foreground, gradient background, and monochrome layer) and a round variant.
- `key.properties`-driven release signing with a documented example and a debug
  fallback, so signed store builds are a configuration step rather than a code
  change.
- Updated README, acceptance checklist, and this changelog.

### Verification
- `dart format .` clean.
- `flutter analyze` clean.
- `flutter test` passes 123 tests, covering domain rules, simulation integrity,
  every journey flow, navigation tap-through, and accessibility layout checks.

### Constraints honoured
- No backend, REST/GraphQL, Firebase, Supabase, cloud database, analytics,
  telemetry, remote image, external map, GPS, real driver, or payment gateway.
- All fares, wallets, drivers, orders, ratings, and receipts are labelled as
  fictional demo data.
- GoMotion is an original identity; no third-party operator branding or assets
  are used.