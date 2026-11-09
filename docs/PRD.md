# Product Requirements Document

## 1. Summary
GoMotion is a fully offline ride-hailing experience simulator for Android and iOS. It demonstrates the end-to-end interaction patterns of mobility, food ordering, and parcel delivery applications using deterministic local fixtures and in-memory state.

## 2. Problem and opportunity
Developers and learners need a realistic, interactive mobile product to explore Flutter UI composition, animation, navigation, and state management without requiring production infrastructure or real-world integrations.

## 3. Goals
- Deliver a coherent premium mobile experience with original branding.
- Demonstrate complete simulated ride, food, and parcel journeys.
- Keep all workflows functional without network access.
- Make simulation behavior deterministic and testable.
- Provide an accessible, maintainable open-source foundation.

## 4. Non-goals
Real transportation dispatch, real courier operations, live maps/GPS, real money, payment processing, backend services, account authentication, cloud sync, and production-grade commerce.

## 5. Audiences
Flutter learners, mobile UI/UX practitioners, open-source contributors, and people evaluating interactive app prototypes.

## 6. Functional requirements
### Home
Greeting, profile avatar, destination search, illustrated local map, service shortcuts, promotional carousel, popular/recent/saved destinations, animated navigation.
### Ride
Pickup/destination selection, local search, route preview, vehicle selection, fare estimate, promo application, booking confirmation.
### Matching and trip
Radar search, deterministic driver assignment, driver/vehicle card, cancellation, animated driver approach, trip progression, ETA, pickup confirmation, arrival, completion.
### Payment
Fare breakdown, cash/demo wallet selection, local payment confirmation, receipt, rating/review. All values must be visibly labeled demo.
### GoFood
Restaurant browse/detail, categories, menu, cart, quantity controls, checkout, courier matching/tracking, receipt.
### GoSend
Sender/recipient, package type, fee estimate, courier matching, pickup, progress, completion receipt.
### Activity
Trips, cancellations, food orders, parcel deliveries, transaction details, receipts.
### Profile/rewards
Fictional profile, demo wallet, rewards, favorites, settings, app info, reset simulation.

## 7. Quality requirements
- Offline after install; no runtime network calls.
- Smooth 60 FPS target on representative supported devices.
- Reduced-motion support and accessible semantics.
- No duplicate active ride, payment, or activity record.
- Unit-testable state machines and deterministic fixtures.
- Responsive layouts for supported phone sizes; handle safe areas and text scaling.

## 8. User journeys
1. First launch → optional onboarding → home.
2. Home → choose destination → choose vehicle → review fare → confirm → search → assigned driver → driver arrival → ride → complete → pay → rate → receipt/activity.
3. Home → GoFood → restaurant → menu → cart → checkout → courier → delivered → receipt.
4. Home → GoSend → addresses/package → estimate → confirm → courier → picked up → delivered → receipt.
5. Profile → settings → reset simulation → confirmation → clean demo state.

## 9. Success criteria
All core journeys complete offline; all state transitions covered by tests; no dead controls; fixtures validate; visual system consistent; release checks pass.
