# Technical Stack

| Area | Choice | Notes |
|---|---|---|
| Language/UI | Flutter + Dart | Stable channel |
| State | Riverpod | Immutable feature state |
| Navigation | GoRouter | Named routes |
| Motion | AnimationController, flutter_animate | Use sparingly and dispose |
| Vector/complex motion | Lottie / Rive | Bundled assets only; optional |
| Offline map | CustomPainter | Schematic local illustration |
| Fixtures | JSON bundled assets | No remote data |
| Preferences | SharedPreferences (optional) | Simple non-sensitive settings |
| Tests | flutter_test | Unit, widget, integration |

Pin compatible package versions during implementation and commit `pubspec.lock` for the app. Review licenses and maintenance status before adding dependencies. Do not add packages that introduce required network access.
