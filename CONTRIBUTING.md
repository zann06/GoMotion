# Contributing

Thanks for considering a contribution to GoMotion.

## Before opening a change
- Read `AGENTS.md`, `docs/ARCHITECTURE.md`, and the relevant feature specification.
- Open an issue for substantial behavior or architecture changes.
- Keep the application fully offline and preserve the fictional-demo boundary.

## Development workflow
1. Fork the repository and create a focused branch (`feat/ride-tracking`, `fix/cart-quantity`).
2. Make the smallest coherent change.
3. Add or update tests.
4. Run `dart format .`, `flutter analyze`, and `flutter test`.
5. Update documentation and `CHANGELOG.md` when behavior or public interfaces change.
6. Open a pull request using the repository template.

## Pull request expectations
Describe the user-visible change, implementation approach, test evidence, screenshots/video for UI changes, and any accessibility or reduced-motion considerations. Do not include secrets, personal data, real payment details, or proprietary assets.

## Code conventions
Prefer immutable domain models, explicit state transitions, small widgets, typed route names, and repository interfaces. Avoid business logic in build methods. Use meaningful names and document non-obvious simulation behavior.

## Reporting issues
Use the bug report template. Include Flutter/Dart versions, device/OS, reproduction steps, expected/actual behavior, and logs with private information removed.
