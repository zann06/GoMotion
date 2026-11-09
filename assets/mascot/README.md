# GoMotion mascot assets

The GoMotion mascot is one original character: a friendly rider with dark navy
hair, an electric-blue helmet carrying a white **G**, a deep-blue rider jacket
with white accent stripes, black riding gloves, and a confident, approachable
expression.

Today the character is **drawn in code** (`lib/core/widgets/mascot_art.dart`) so
the app ships fully offline with zero bundled art and renders crisply at every
density. This folder exists so higher-fidelity pose art can be dropped in later
without touching a single call site.

## Dropping in pose bitmaps

1. Add the pose PNGs below using these exact file names (transparent background,
   square, 512×512 or larger, character consistent with the master reference):

   | Pose    | File                        | Used by                                   |
   | ------- | --------------------------- | ----------------------------------------- |
   | hero    | `mascot_home.png`           | Home hero card                            |
   | wave    | `mascot_wave.png`           | Splash, welcome, friendly empty states    |
   | loading | `mascot_loading.png`        | Loading states                            |
   | ride    | `mascot_ride.png`           | GoRide pose + GoRide map marker           |
   | car     | `mascot_car.png`            | GoCar / GoCar Premium pose + car marker   |
   | food    | `mascot_food.png`           | GoFood banner, food empty state           |
   | send    | `mascot_send.png`           | GoSend banner, parcel empty state         |
   | success | `mascot_success.png`        | Ride / food / parcel receipts             |
   | error   | `mascot_error.png`          | Empty search results and recoverable errors |

   Optional dedicated top-down marker art: `mascot_marker_ride.png`,
   `mascot_marker_car.png`.

   Keep the master reference here as `mascot_reference.png` for art direction.

2. `assets/mascot/` is already declared under `flutter: assets:` in
   `pubspec.yaml`, so no manifest change is needed.

3. Flip `MascotAssets.bundled` to `true` in
   `lib/core/constants/mascot_assets.dart`. `Mascot` and `MascotMapMarker` then
   prefer the bitmaps and fall back to the drawn character per pose, so a partial
   drop-in is safe.

4. Prefer WebP (or optimized PNG) at 1×/2×/3× sizes; keep each file under ~80 KB
   so the tracking screen stays light. Run `flutter test` afterwards.

## Rules

- One character only: never restyle the face, clothing, colours, or proportions
  between poses.
- Do not use Grab/Gojek logos, names, or proprietary assets. GoRide, GoCar,
  GoCar Premium, GoFood, and GoSend are fictional simulation labels here.
- Keep the mascot proportional and never place it over important information.
