# Design Refresh — Deep Blue

> Recorded before implementation, per the working protocol in `AGENTS.md`
> ("do not change approved decisions without recording a proposal first").
> Approved by the product owner during the local demo review.

## Motivation
The first complete build used an indigo-first palette. During the device review
the owner asked for a cleaner, more premium look with a **deep blue** identity,
a map preview that shows the **vehicle matching the selected option**, and more
consistent iconography, taking inspiration from the information architecture of
ShopeeFood, Gojek, and Grab **without copying any of their assets, names, or
exact screens**.

## Decisions

### 1. Palette — deep blue primary
| Token | Old | New | Role |
|---|---|---|---|
| `deepBlue` | — | `#0E2A6E` | Deepest brand blue; hero gradient start |
| `primaryIndigo` | `#4F46E5` | `#1D4ED8` | Primary actions, active states |
| `electricBlue` | `#2563EB` | `#2563EB` | Links, secondary emphasis |
| `brightBlue` | — | `#3B82F6` | Decorative map/illustration detail |
| `violet` | `#8B5CF6` | `#7C3AED` | Restrained tertiary accent (Send) |
| `deepNavy` | `#111827` | `#0B1220` | Main text / dark surfaces |
| `softWhite` | `#F5F6FF` | `#F3F6FE` | App background |
| `neutralGray` | `#64748B` | `#5B6B85` | Secondary text |
| `lightBorder` | `#E5E7EB` | `#E2E8F5` | Dividers and outlines |

Token **names are preserved** (`primaryIndigo`, `electricBlue`, …) so the change
is a value-level restyle rather than a codebase-wide rename. New tokens
(`deepBlue`, `brightBlue`, map detail colours) are additive.

The primary gradient is now `deepBlue → primaryIndigo → electricBlue`. Violet is
kept only as a small accent so the brand still spans blue/violet while reading
as deep blue.

### 2. Schematic map — vehicle preview
- `SchematicMap` gained `vehicle` (`VehicleKind`), `markerIcon` (courier
  override), and `nearby` (`MapVehiclePin`) parameters.
- The moving marker is now a white chip with a soft halo and the **icon of the
  selected vehicle** (motorbike / car / premium).
- Vehicle selection previews the chosen vehicle at 24% along the route and
  updates live when a different card is tapped.
- Ride tracking shows the chosen vehicle; GoFood/GoSend tracking show courier
  icons.
- The illustration gained city blocks, wider roads with casings, and a subtle
  ground wash.

### 3. Iconography and components
- New `lib/core/constants/app_icons.dart` centralises service and vehicle icons
  and defines `VehicleKind.fromCategory`.
- Bottom navigation: active item sits in a soft blue pill with a filled icon.
- Home service tiles use gradient icon wells with coloured shadows.
- The home avatar opens the profile; the hero card carries an explicit `Demo`
  pill and a clear search affordance.

## Constraints preserved
- Fully offline: no new assets, network calls, maps, or GPS.
- Green remains semantic success / map detail only.
- All money, people, and services remain labelled as fictional/demo.
- No competitor logos, names, colours, or screen copies.

## Verification
`dart format .`, `flutter analyze`, and `flutter test` all pass. New regression
coverage asserts the map preview follows the selected vehicle. Visual checks
were captured from the release web build at phone viewport size.