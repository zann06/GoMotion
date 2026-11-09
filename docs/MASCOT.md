# GoMotion Mascot System

The GoMotion mascot is the app's brand character: a friendly, energetic rider
with dark navy hair, an electric-blue helmet carrying a white **G**, a deep-blue
rider jacket with white accent stripes, and black riding gloves. It is an
**original** character drawn from brand tokens — no competitor logos, names, or
assets, and no network dependency.

## Why it is drawn in code

The app must run fully offline and ship no third-party art, and the build
environment has no image tooling. So the character is composed from flat vector
shapes in `MascotArtPainter`, which renders crisply at any density, keeps the app
bundle small, and guarantees one identical character everywhere.

When higher-fidelity pose bitmaps become available, follow
`assets/mascot/README.md`: drop the PNGs in, then flip
`MascotAssets.bundled` to `true`. Call sites never change.

## Layers

| File | Responsibility |
| ---- | -------------- |
| `lib/core/constants/mascot_assets.dart` | Poses (`MascotVariant`), motion intents (`MascotAnimation`), sizes (`MascotSize`), asset paths, and the `bundled` switch. |
| `lib/core/widgets/mascot_art.dart` | The code-drawn character and every pose, including the motorbike and car scenes. |
| `lib/core/widgets/mascot.dart` | The reusable `Mascot` widget, the `MascotBanner` service strip, and `MascotLoadingDots`. |
| `lib/core/widgets/mascot_map_marker.dart` | The animated vehicle marker for the schematic map. |

## Poses and placement

| Pose | Motion | Where it appears |
| ---- | ------ | ---------------- |
| `hero` (thumbs-up) | idle | Home hero card |
| `wave` | wave | Splash, welcome, activity/cart empty states |
| `loading` | idle | Loading treatments |
| `ride` (motorbike) | riding | GoRide map marker, ride matching radar, vehicle preview |
| `car` (driving) | driving | GoCar / GoCar Premium map marker, vehicle preview |
| `food` (bag + drink) | deliver | GoFood banner and restaurant empty state |
| `send` (parcel) | deliver | GoSend banner |
| `success` | happy | Ride / food / parcel receipts |
| `error` (puzzled) | idle | Empty destination search, fixture-load failure |

## Animation rules

- Every choreography is a **finite one-shot**: it plays once on mount and then
  holds still. There is no perpetual ticker, which keeps the frame rate steady
  and keeps widget tests able to settle.
- Under reduced motion the character renders its settled frame immediately, and
  it is never left invisible.
- Animation never stretches or skews the character. The map marker specifically
  keeps the character upright and rotates only a small compass tick to show the
  travel bearing, so the face never distorts.

## Live map marker

`MascotMapMarker` is placed by `SchematicMap` at the simulated vehicle position:

- the position comes from `RouteGeometry.pointAt(route, progress)`;
- the heading tick uses `RouteGeometry.bearingAt(route, progress)` (radians,
  zero = north);
- `isMoving` adds faint trailing puffs while travelling;
- the marker eases to each new position with `AnimatedPositioned`, so movement is
  smooth rather than stepped;
- zoom, pan, the route polyline, origin/destination pins, and nearby idle
  vehicles are untouched.

The position is **simulated** from bundled fixtures and a deterministic clock —
there is no GPS, no driver backend, and no live tracking. The map and the marker
are labelled as demo data.
