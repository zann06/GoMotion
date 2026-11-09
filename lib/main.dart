import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers/app_providers.dart';
import 'app/providers/reduced_motion_provider.dart';
import 'data/preferences/preferences_store.dart';

/// Bootstraps GoMotion.
///
/// Startup work is local only: load simple preferences and restore the saved
/// in-app motion override. Fixtures load lazily behind a loading state so the
/// first frame is immediate.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final preferences = await _loadPreferences();

  final container = ProviderContainer(
    overrides: [preferencesStoreProvider.overrideWithValue(preferences)],
  );

  // Restore the persisted motion override before the first frame so the app
  // never animates once and then stops.
  if (preferences.reduceMotionOverride) {
    container.read(inAppReduceMotionProvider.notifier).set(true);
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const GoMotionApp()),
  );
}

/// Loads preferences, falling back to an in-memory store if the platform
/// plugin is unavailable. Preferences are optional by design.
Future<PreferencesStore> _loadPreferences() async {
  try {
    return await SharedPreferencesStore.load();
  } on Object catch (error) {
    debugPrint('Preferences unavailable, using in-memory store: $error');
    return InMemoryPreferencesStore();
  }
}
