# Changelog

All notable changes to GoMotion will be documented here.

## [0.1.0] - Unreleased

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

### Added — Phase 1 (partial, in progress)
- GoRouter route table and four-branch navigation shell.
- Core widget library: page scaffold, card, buttons, empty/loading/error states,
  schematic demo map, brand mark, bottom navigation, and fixture gate.
- Initial Home, Activity, Rewards, and Profile screens.
- Reduced-motion providers honouring both the platform setting and an in-app
  override persisted via `shared_preferences`.

### Not yet implemented
- Ride booking, driver tracking, payment, GoFood, and GoSend journeys. Phases
  2–10 of `docs/IMPLEMENTATION_PLAN.md` are outstanding, so the app is not yet a
  complete ride-hailing simulator.
