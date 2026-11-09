# Offline Strategy

GoMotion is offline by design, not an online app with a fallback mode.

- Bundle all images, icons, fonts, Lottie/Rive files, and JSON fixtures.
- No runtime HTTP clients, webviews, external map tiles, geocoding, GPS, analytics, remote config, or push notifications.
- Use CustomPainter to draw an abstract schematic map from local coordinates.
- Use in-memory repositories for mutable demo state.
- Optional SharedPreferences only for simple preferences such as onboarding and reduced motion.
- Include a clear “Demo simulation — works offline” label in app information.
- Test in airplane mode after clean installation.
- Inspect dependency tree for packages that initiate network requests; document any unavoidable platform behavior.
