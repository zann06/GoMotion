import 'package:shared_preferences/shared_preferences.dart';

/// Storage for the only data that may be persisted.
///
/// `docs/ARCHITECTURE.md` permits SharedPreferences for simple preferences
/// only: onboarding completion, reduced motion, and theme choice. Nothing
/// sensitive, and never simulated money or activity history.
abstract interface class PreferencesStore {
  bool get hasSeenOnboarding;
  Future<void> setHasSeenOnboarding(bool value);

  bool get reduceMotionOverride;
  Future<void> setReduceMotionOverride(bool value);

  /// Clears preference overrides, used by reset simulation.
  Future<void> clear();
}

/// SharedPreferences-backed implementation.
final class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kOnboarding = 'gomotion.onboarding.seen';
  static const String _kReduceMotion = 'gomotion.motion.reduce';

  /// Loads the store, tolerating platforms where preferences are unavailable.
  static Future<SharedPreferencesStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStore(prefs);
  }

  @override
  bool get hasSeenOnboarding => _prefs.getBool(_kOnboarding) ?? false;

  @override
  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_kOnboarding, value);
  }

  @override
  bool get reduceMotionOverride => _prefs.getBool(_kReduceMotion) ?? false;

  @override
  Future<void> setReduceMotionOverride(bool value) async {
    await _prefs.setBool(_kReduceMotion, value);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_kOnboarding);
    await _prefs.remove(_kReduceMotion);
  }
}

/// In-memory store for tests and for platforms without prefs support.
final class InMemoryPreferencesStore implements PreferencesStore {
  InMemoryPreferencesStore({
    bool hasSeenOnboarding = false,
    bool reduceMotionOverride = false,
  }) : _hasSeenOnboarding = hasSeenOnboarding,
       _reduceMotionOverride = reduceMotionOverride;

  bool _hasSeenOnboarding;
  bool _reduceMotionOverride;
  @override
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  @override
  Future<void> setHasSeenOnboarding(bool value) async {
    _hasSeenOnboarding = value;
  }

  @override
  bool get reduceMotionOverride => _reduceMotionOverride;

  @override
  Future<void> setReduceMotionOverride(bool value) async {
    _reduceMotionOverride = value;
  }

  @override
  Future<void> clear() async {
    _hasSeenOnboarding = false;
    _reduceMotionOverride = false;
  }
}
