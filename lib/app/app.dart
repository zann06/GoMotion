import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import 'providers/reduced_motion_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Global messenger so non-widget layers can show brief confirmations.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'rootScaffoldMessenger');

/// The GoMotion application root.
///
/// Owns the [GoRouter] instance for the lifetime of the app, applies the brand
/// theme, and keeps the motion preference in sync with the platform setting.
class GoMotionApp extends ConsumerStatefulWidget {
  const GoMotionApp({this.initialLocation, this.observers, super.key});

  /// Overrides the start route, used by tests.
  final String? initialLocation;

  /// Navigation observers, used by tests.
  final List<NavigatorObserver>? observers;

  @override
  ConsumerState<GoMotionApp> createState() => _GoMotionAppState();
}

class _GoMotionAppState extends ConsumerState<GoMotionApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation ?? '/',
    observers: widget.observers ?? const [],
  );

  bool? _lastSystemMotion;

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Pushes the platform animation setting into provider space.
  ///
  /// Runs after layout is scheduled to avoid mutating another provider during
  /// this widget's build.
  void _syncSystemMotion(bool enabled) {
    if (_lastSystemMotion == enabled) return;
    _lastSystemMotion = enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(systemReduceMotionProvider.notifier).sync(enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: AppTheme.light(),
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        _syncSystemMotion(media.disableAnimations);

        // Clamp text scaling so very large accessibility sizes cannot break
        // critical layouts, while still honouring the preference.
        final clamped = media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.35,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: clamped),
          child: ColoredBox(
            color: AppColors.softWhite,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Overscroll feel for the whole app.
///
/// Scrolling uses one physics everywhere ([BouncingScrollPhysics]) so long
/// lists, sheets, and short cards behave the same on every platform, and the
/// platform stretch/glow indicator is dropped because the bounce already
/// communicates the edge. Reducing it to a single consistent behaviour is what
/// makes dragging feel smooth rather than platform-dependent.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
