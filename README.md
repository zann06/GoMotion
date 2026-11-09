# GoMotion
**Move smarter. Feel every journey.**

GoMotion is an offline-first, fictional ride-hailing experience simulator for Android and iOS, built with Flutter and Dart. It recreates the interaction patterns of a modern mobility superapp for learning, demonstrations, and experimentation. It is not a real transportation, delivery, or payment service.

![GoMotion product showcase](design/references/gomotion-product-showcase.png)

## Product principles
- Fully offline: no backend, API, cloud database, authentication server, remote maps, or remote images.
- Honest simulation: all drivers, fares, wallets, orders, ratings, and receipts are fictional demo data.
- Original identity: electric indigo, blue, and violet; no copied operator branding or proprietary assets.
- Complete local interactions: no dead-end buttons; every visible action has a defined local outcome.
- Maintainable code: feature-first organization, clean boundaries, Riverpod state management, and testable state machines.

## Features
Ride booking and tracking, simulated driver matching, demo payment and receipts, GoFood ordering, GoSend parcel delivery, activity history, profile, rewards, saved places, and settings.

## Quick start
1. Install the Flutter stable SDK and verify `flutter doctor`.
2. Clone the repository and enter its directory.
3. Run `flutter pub get`.
4. Run `flutter analyze` and `flutter test`.
5. Launch with `flutter run` on an Android emulator/device. iOS builds require macOS and Xcode.

This production package is the product/design/engineering handover. It is not a completed Flutter application; the implementation agent must create the Flutter source code using the specifications and references here.

## Build
- Android debug: `flutter build apk --debug`
- Android release: `flutter build apk --release`
- iOS release (macOS): `flutter build ipa --release`

## Repository setup
Replace `<GITHUB_USERNAME>` and `<REPOSITORY>` with the repository owner's values:
```bash
git init
git add .
git commit -m "docs: add GoMotion production handover"
git branch -M main
git remote add origin https://github.com/<GITHUB_USERNAME>/<REPOSITORY>.git
git push -u origin main
```

## Documentation map
See `docs/` for product, design, architecture, data, simulation, privacy, testing, and roadmap specifications. See `prompts/` for coding-agent task prompts. See `AGENTS.md` for mandatory implementation constraints.

## License
MIT. See [LICENSE](LICENSE).
