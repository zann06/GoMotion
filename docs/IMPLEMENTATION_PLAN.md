# Implementation Plan

## Phase 0 — Flutter foundation
- Objectives: create stable Flutter app shell and CI.
- Tasks: initialize app, dependencies, lint, folder structure, fixture loader, theme bootstrap.
- Deliverables: runnable shell, pubspec, CI, fixture validation.
- Dependencies: none.
- Tests: app boots; fixtures parse.
- Done: analyze/test pass on clean checkout.

## Phase 1 — Design system and app shell
- Objectives: establish visual language and navigation.
- Tasks: tokens, typography, buttons/cards/sheets, GoRouter, bottom nav, reduced motion.
- Deliverables: reusable component library and shell.
- Dependencies: Phase 0.
- Tests: component/widget tests, route tests.
- Done: all primary routes render consistently.

## Phase 2 — Home and local destinations
- Objectives: home discovery and destination selection.
- Tasks: illustrated map, search/filter, popular/recent/saved locations.
- Deliverables: home and destination flow.
- Dependencies: Phase 1, locations fixture.
- Tests: search and selection.
- Done: destination selection works offline.

## Phase 3 — Vehicle selection and booking
- Objectives: fare review and booking confirmation.
- Tasks: vehicle cards, fare engine, promo rules, booking guard.
- Deliverables: ride draft/review/confirmation.
- Dependencies: Phase 2, vehicles/promos.
- Tests: fare, promo, duplicate booking.
- Done: one valid ride can be confirmed.

## Phase 4 — Driver matching and tracking
- Objectives: complete ride simulation.
- Tasks: deterministic assignment, radar, driver approach, trip route and ETA.
- Deliverables: matching and tracking journey.
- Dependencies: Phase 3, drivers.
- Tests: fake clock, cancellation, stale timer.
- Done: lifecycle reaches COMPLETED reliably.

## Phase 5 — Payment and activity
- Objectives: close ride journey.
- Tasks: demo cash/wallet, atomic payment, receipt, rating, history.
- Deliverables: paid/rated ride and activity details.
- Dependencies: Phase 4.
- Tests: duplicate payment and receipt persistence in session.
- Done: complete ride journey passes integration test.

## Phase 6 — GoFood
- Objectives: local restaurant ordering.
- Tasks: browse, detail, menu, cart, checkout, courier and tracking.
- Deliverables: complete food order and receipt.
- Dependencies: Phase 1, restaurant/menu fixtures, shared simulation.
- Tests: cart, invalid checkout, cancellation.
- Done: delivered order appears once in activity.

## Phase 7 — GoSend
- Objectives: local parcel delivery flow.
- Tasks: sender/recipient, package, fee, courier, pickup, transit.
- Deliverables: completed parcel receipt.
- Dependencies: Phase 1, delivery fixtures.
- Tests: validation, cancellation, lifecycle.
- Done: delivery appears once in activity.

## Phase 8 — Profile and rewards
- Objectives: complete secondary product areas.
- Tasks: profile, demo wallet, favorites, rewards, settings, reset.
- Deliverables: functional profile/rewards.
- Dependencies: Phases 2, 5.
- Tests: favorites, rewards, reset.
- Done: all profile controls work locally.

## Phase 9 — Animation polish and QA
- Objectives: improve motion and quality.
- Tasks: tune transitions, haptics, reduced motion, accessibility, profiling.
- Deliverables: polished release candidate.
- Dependencies: feature completion.
- Tests: full suite, performance and accessibility review.
- Done: no critical defects or motion regressions.

## Phase 10 — Production builds and GitHub release
- Objectives: publish reproducible open-source release.
- Tasks: Android/iOS builds, README verification, issue templates, release notes, tags.
- Deliverables: signed/unsigned builds as appropriate, GitHub release.
- Dependencies: Phase 9.
- Tests: clean clone build and install.
- Done: release checklist signed off by maintainer.
