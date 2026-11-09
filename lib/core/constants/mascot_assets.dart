/// Mascot pose families, animation intents, sizes, and asset slots.
///
/// GoMotion ships one original mascot character — a friendly rider in a
/// deep-blue jacket and electric-blue helmet — reused across the app so the
/// brand reads as one character everywhere.
///
/// The character is currently drawn in code (see
/// `lib/core/widgets/mascot_art.dart`) so the app stays fully offline with zero
/// bundled art. When higher-fidelity pose art becomes available, drop the PNGs
/// into `assets/mascot/` using the names in [MascotAssets.files], add
/// `- assets/mascot/` to `pubspec.yaml`, and flip [MascotAssets.bundled] to
/// true. The [Mascot] widget then prefers the bitmaps and falls back to the
/// drawn character automatically, so no call site changes.
library;

/// A pose of the GoMotion mascot.
enum MascotVariant {
  /// Confident thumbs-up greeting. Used on the home hero.
  hero,

  /// Open-handed wave. Used on the splash, welcome, and friendly empty states.
  wave,

  /// Neutral, ready pose used while content is loading.
  loading,

  /// Seated on a motorbike — the GoRide pose.
  ride,

  /// At the wheel of a car — the GoCar / GoCar Premium pose.
  car,

  /// Carrying a food bag and drink — the GoFood pose.
  food,

  /// Carrying a parcel — the GoSend pose.
  send,

  /// Celebrating a completed journey.
  success,

  /// Apologetic / puzzled, for empty search results and recoverable errors.
  error;

  /// The motion that reads best for this pose.
  MascotAnimation get defaultAnimation => switch (this) {
    MascotVariant.hero => MascotAnimation.idle,
    MascotVariant.wave => MascotAnimation.wave,
    MascotVariant.loading => MascotAnimation.idle,
    MascotVariant.ride => MascotAnimation.riding,
    MascotVariant.car => MascotAnimation.driving,
    MascotVariant.food => MascotAnimation.deliver,
    MascotVariant.send => MascotAnimation.deliver,
    MascotVariant.success => MascotAnimation.happy,
    MascotVariant.error => MascotAnimation.idle,
  };

  /// Accessible description of what the mascot is doing.
  String get semanticLabel => switch (this) {
    MascotVariant.hero => 'GoMotion mascot giving a thumbs up',
    MascotVariant.wave => 'GoMotion mascot waving hello',
    MascotVariant.loading => 'GoMotion mascot getting ready',
    MascotVariant.ride => 'GoMotion mascot riding a demo motorbike',
    MascotVariant.car => 'GoMotion mascot driving a demo car',
    MascotVariant.food => 'GoMotion mascot carrying a demo food order',
    MascotVariant.send => 'GoMotion mascot carrying a demo parcel',
    MascotVariant.success => 'GoMotion mascot celebrating a completed demo',
    MascotVariant.error => 'GoMotion mascot looking puzzled',
  };

  /// The mascot pose for a simulated ride category.
  static MascotVariant forRideCategory(String? category) {
    final normalised = (category ?? '').toLowerCase();
    if (normalised.contains('ride') || normalised.contains('bike')) {
      return MascotVariant.ride;
    }
    return MascotVariant.car;
  }
}

/// The motion intent applied to a [MascotVariant].
///
/// Every choreography is a short, finite one-shot: it plays once on mount and
/// then holds still. Continuous loops are deliberately avoided so the mascot
/// never competes with content and the app keeps a steady frame rate.
enum MascotAnimation {
  /// No motion; the pose is drawn as-is.
  none,

  /// Gentle rise-and-settle entrance.
  idle,

  /// Rise, then wave the raised hand twice.
  wave,

  /// Springy celebration pop.
  happy,

  /// Rise and lean forward, as if setting off.
  riding,

  /// Rise with a light steering tilt.
  driving,

  /// Rise with a soft sway, as if carrying something.
  deliver,
}

/// Discrete mascot sizes. Kept small so the mascot never dominates a screen.
enum MascotSize {
  /// Inline, next to a label.
  small,

  /// Standard inline illustration.
  medium,

  /// Section-level illustration.
  large,

  /// Splash and welcome hero.
  hero;

  /// Edge length in logical pixels.
  double get px => switch (this) {
    MascotSize.small => 44,
    MascotSize.medium => 72,
    MascotSize.large => 104,
    MascotSize.hero => 148,
  };
}

/// Bundled mascot art slots and the drop-in enable switch.
abstract final class MascotAssets {
  /// Directory that holds the optional pose bitmaps.
  static const String directory = 'assets/mascot/';

  /// The master character reference, kept for art direction.
  static const String reference = '${directory}mascot_reference.png';

  /// Whether pose bitmaps are bundled.
  ///
  /// Leave `false` while the character is drawn in code. Set to `true` after
  /// dropping the PNGs into [directory] and declaring `- assets/mascot/` under
  /// `flutter: assets:` in `pubspec.yaml`.
  static const bool bundled = false;

  /// File name for each pose. Drop-in ready.
  static const Map<MascotVariant, String> files = {
    MascotVariant.hero: '${directory}mascot_home.png',
    MascotVariant.wave: '${directory}mascot_wave.png',
    MascotVariant.loading: '${directory}mascot_loading.png',
    MascotVariant.ride: '${directory}mascot_ride.png',
    MascotVariant.car: '${directory}mascot_car.png',
    MascotVariant.food: '${directory}mascot_food.png',
    MascotVariant.send: '${directory}mascot_send.png',
    MascotVariant.success: '${directory}mascot_success.png',
    MascotVariant.error: '${directory}mascot_error.png',
  };

  /// Dedicated top-down marker art for the vehicle map markers.
  static const Map<MascotVariant, String> markerFiles = {
    MascotVariant.ride: '${directory}mascot_marker_ride.png',
    MascotVariant.car: '${directory}mascot_marker_car.png',
  };

  /// The bitmap for [variant], or null while art is drawn in code.
  static String? fileFor(MascotVariant variant) =>
      bundled ? files[variant] : null;

  /// The marker bitmap for [variant], or null while art is drawn in code.
  static String? markerFileFor(MascotVariant variant) =>
      bundled ? markerFiles[variant] : null;
}
