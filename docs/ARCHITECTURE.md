# Architecture

## Pattern
Feature-first + Clean Architecture. Each feature owns presentation, application orchestration, domain rules, and data adapters where applicable. Shared primitives live in `core/`; cross-feature simulation policies live in `simulation/`.

## Layers
- **Presentation:** screens, widgets, theme, route bindings. No business rules.
- **Application:** Riverpod providers/notifiers, use cases, orchestration, UI state.
- **Domain:** entities, value objects, repository contracts, validators, state machines.
- **Data:** fixture loaders, DTOs, JSON parsing, repository implementations.
- **Simulation:** deterministic clock, seeded assignment, progression scheduler, lifecycle guards.

## Dependency direction
Presentation → Application → Domain. Data implements Domain contracts. Simulation is injected into application use cases through interfaces; domain must not import Flutter UI or plugin packages.

## Suggested structure
See `project_structure.txt`. Use `features/ride`, `features/food`, `features/send`, `features/home`, `features/activity`, `features/profile`, and `features/rewards`.

## State management
Riverpod providers expose immutable state. Prefer Notifier/AsyncNotifier only where loading/async parsing is needed. Since data is bundled, startup loading is local and deterministic. Keep provider scopes narrow and avoid global mutable singletons.

## Navigation
GoRouter with named routes and typed route helpers where practical. Guard flow routes against invalid lifecycle states; deep links are not required for MVP.

## Error handling
Parse fixture data at startup with explicit failures and useful developer diagnostics. User-facing failures should be actionable and must not expose stack traces.

## Persistence
In-memory state is authoritative for a session. SharedPreferences may store simple preferences only (onboarding complete, reduced motion, selected theme). Do not persist sensitive data or imply cloud sync.
