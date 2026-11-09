# Design System

## Brand
GoMotion — “Move smarter. Feel every journey.” Original mobility-tech identity with a deep-blue primary family and a restrained violet accent. Never use green as the primary brand color. See `docs/DESIGN_REFRESH.md` for the deep-blue refresh rationale.

## Color tokens
| Token | Hex | Usage |
|---|---|---|
| deepBlue | #0E2A6E | Hero gradient start, deep brand surfaces |
| primaryIndigo | #1D4ED8 | Primary actions, active states |
| electricBlue | #2563EB | Links, secondary emphasis |
| brightBlue | #3B82F6 | Map and illustration detail |
| violet | #7C3AED | Restrained tertiary accent |
| deepNavy | #0B1220 | Main text / dark surfaces |
| softWhite | #F3F6FE | App background |
| white | #FFFFFF | Cards and sheets |
| neutralGray | #5B6B85 | Secondary text |
| lightBorder | #E2E8F5 | Dividers and outlines |
| success | #16A34A | Semantic success only |

## Typography
Use a modern sans-serif. Suggested hierarchy: display 28–32/700, title 22–24/700, section 16–18/650, body 14–16/400, caption 11–12/500. Use bundled fonts only if licensing permits; otherwise platform sans-serif.

## Layout
8-point spacing base. Screen horizontal padding 20–24. Card radius 20–24; button radius 16; chip radius 999. Minimum touch target 48×48 logical pixels. Respect safe areas.

## Components
Primary gradient button (deepBlue→primaryIndigo→electricBlue), tonal button, icon service tile, destination row, vehicle option, driver card, fare breakdown, promo card, status pill, map pin, vehicle map marker, bottom sheet, receipt row, empty state, skeleton.

## Elevation and effects
Use subtle shadows and restrained gradients. Avoid glow-heavy styling, broad blur, and stacked decorative effects. Prefer clear borders and surface contrast.

## Iconography
Consistent rounded line icons with 1.8–2.0 stroke. Service and vehicle icons live in `lib/core/constants/app_icons.dart` so the home shortcuts, vehicle picker, active-journey banner, bottom navigation, and map marker stay identical. Create the original GoMotion mark from a forward-motion path/chevron motif; do not approximate competitor marks.

## States
Default, pressed, focused, disabled, loading, selected, success, warning, and error. Every state must have sufficient contrast and semantic labeling.
