# UI/UX Guidelines

## Navigation
Bottom navigation: Home, Activity, Rewards (or Profile depending on final IA), Profile. Keep active item indigo; inactive items neutral. Ride/food/send flows are nested routes with clear back behavior.

## Screen composition
Start with a clear page title or greeting, then primary task, supporting content, and optional discovery modules. Avoid generic admin-dashboard layouts.

## Forms and selection
Use labeled fields, sensible defaults, inline validation, and clear selected states. Do not rely on placeholder text as a label. Keep confirmation details visible before committing a simulated action.

## Map interaction
The offline map is an illustrated schematic, not a geographic map. Label it “Demo map”. Support selecting known fixture locations and drawing a schematic route; never imply live GPS accuracy.

## Bottom sheets
Use draggable sheets only when interaction benefits. Keep primary CTA visible and avoid nested sheets. Dismissal must preserve or intentionally discard state.

## Feedback
Use brief snackbars for reversible confirmations, dialogs for destructive reset/cancellation, and dedicated result screens for booking/payment completion.

## Accessibility
Semantic labels for icon-only buttons, scalable text, logical focus order, adequate contrast, large touch targets, and reduced-motion alternatives. Never convey status by color alone.

## Empty/error states
Explain why the list is empty and offer a local next action. Offline status should not appear as an error because offline is the intended mode.
