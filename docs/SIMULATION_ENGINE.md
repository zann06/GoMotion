# Simulation Engine

## Principles
Deterministic, local, clock-injectable, idempotent, and testable. The engine produces state changes; widgets only render them.

## Ride lifecycle
`IDLE → SELECTING → SEARCHING → DRIVER_ASSIGNED → DRIVER_ARRIVING → IN_PROGRESS → COMPLETED → PAID → RATED`

Cancellation is allowed from SELECTING, SEARCHING, DRIVER_ASSIGNED, and DRIVER_ARRIVING. Define whether cancellation during IN_PROGRESS is disabled or a separate support-only demo flow; default is disabled. Terminal states cannot progress further.

## Invariants
- At most one active ride.
- One booking confirmation per ride ID.
- One payment per completed ride ID.
- One activity record per terminal ride.
- No timer or scheduled progression survives cancellation/reset.
- Progression events carry the lifecycle generation/token; stale tokens are ignored.
- Invalid transitions return a typed domain failure, not silent mutation.

## Simulation clock
Inject `SimulationClock` with `now`, `schedule`, and `cancelAll`. Production demo clock may advance automatically; tests use a fake clock that advances explicitly. Avoid `Future.delayed` scattered through widgets.

## Driver assignment
Load fixture drivers and choose deterministically from a stable seed derived from ride ID or injected test seed. Assignment must be reproducible. Driver status is local sample data.

## Tracking
Represent route as normalized points on the illustrated map. Animate marker position between route points; ETA decreases in discrete simulation ticks. Do not use GPS or geocoding.

## Payment
Payment command checks ride COMPLETED, payment not previously recorded, and selected method. Demo wallet checks sufficient demo balance. Commit payment and activity atomically in the in-memory repository. Never contact a payment processor.

## GoFood state machine
`BROWSING → RESTAURANT_SELECTED → CART_READY → CHECKOUT → MATCHING_COURIER → PREPARING → ON_THE_WAY → DELIVERED → RECEIPT`
Cancellation allowed before PREPARING; later cancellation is disabled in this demo. Cart quantity cannot fall below zero; empty cart cannot checkout.

## GoSend state machine
`DRAFT → QUOTED → CONFIRMED → MATCHING_COURIER → COURIER_ASSIGNED → PICKED_UP → IN_TRANSIT → DELIVERED → RECEIPT`
Cancellation allowed through MATCHING_COURIER. Sender, recipient, and package category are required before quote.

## Reset
Reset requires confirmation, increments generation token, cancels all scheduled tasks, clears in-memory histories/cart/active flows, and restores fixture demo profile/wallet. Ensure repeated reset is safe.
