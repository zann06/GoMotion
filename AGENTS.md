# Instructions for Coding Agents

## Mission
Implement GoMotion as a polished Flutter mobile simulator strictly from this handover. Do not restart product discovery or change approved decisions without recording a proposal first.

## Non-negotiable constraints
1. Entirely offline at runtime. No backend, REST/GraphQL, Firebase, Supabase, cloud DB, analytics, telemetry, remote image, external map API, GPS, real driver, or payment integration.
2. Use Flutter + Dart, Riverpod, GoRouter, feature-first + clean architecture.
3. Brand is electric indigo / blue / violet. Primary must not be green. Green is reserved for semantic success or map illustration details.
4. Every visible interactive control must work locally. Do not ship dead buttons or fake external integrations.
5. Clearly mark fares, wallet balances, promotions, drivers, orders, and receipts as fictional/demo.
6. Do not copy Grab/Gojek logos, names as branding, proprietary assets, or exact screens. Service labels GoRide, GoCar, GoCar Premium, GoFood, and GoSend are fictional simulation labels in this project.
7. Keep presentation, application orchestration, domain rules, data sources, and simulation engine separate.
8. Respect reduced motion, dispose controllers, and target smooth 60 FPS on supported devices.

## Working protocol
- Read README, PRD, ARCHITECTURE, DESIGN_SYSTEM, SIMULATION_ENGINE, DATA_MODEL, OFFLINE_STRATEGY, and acceptance checklist before coding.
- Implement in roadmap order; keep each phase independently testable.
- Use bundled JSON fixtures and deterministic simulation seeds.
- Validate state transitions in domain/application layers, not inside widgets.
- Add unit tests for domain rules and widget/integration tests for critical journeys.
- Update CHANGELOG and acceptance checklist as work lands.
- Never mark a phase complete unless its Definition of Done passes.

## Quality gates
Run `dart format .`, `flutter analyze`, and `flutter test`. Check Android build locally. iOS build is verified on macOS/Xcode CI or by a maintainer.
