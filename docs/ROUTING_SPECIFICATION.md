# Routing Specification

## Route groups
- `/` home
- `/destination/search`
- `/ride/vehicle`
- `/ride/review`
- `/ride/matching`
- `/ride/tracking`
- `/ride/receipt`
- `/food`
- `/food/restaurant/:restaurantId`
- `/food/cart`
- `/food/tracking`
- `/food/receipt`
- `/send`
- `/send/review`
- `/send/tracking`
- `/send/receipt`
- `/activity`
- `/activity/:activityId`
- `/profile`
- `/rewards`
- `/settings`

## Route behavior
Use GoRouter named routes. Pass stable IDs, not whole mutable objects, through route extras. Load entities from repositories/providers. Invalid or stale IDs show a recoverable not-found state. Flow routes verify the relevant local state; redirect to the nearest valid step when state is missing.

## Back navigation
Back from a form preserves draft input. Back from a committed flow never silently reverses payment or delivery. Reset and cancellation use explicit confirmation. Receipt routes remain accessible from activity after flow completion.
