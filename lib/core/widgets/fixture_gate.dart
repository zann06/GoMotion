import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/widgets/app_states.dart';
import '../../domain/repositories/fixture_repository.dart';

/// Renders [builder] once the bundled fixtures have loaded.
///
/// Centralises the loading and failure presentation so every feature gets the
/// same recoverable error treatment. Technical failure detail is logged in debug
/// builds only and is never shown to the user.
class FixtureGate extends ConsumerWidget {
  const FixtureGate({required this.builder, super.key, this.loading});

  final Widget Function(BuildContext context, FixtureBundle bundle) builder;

  /// Optional custom loading state; defaults to a skeleton list.
  final Widget? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fixtureBundleProvider);
    return async.when(
      loading: () => loading ?? const AppSkeletonList(itemCount: 4),
      error: (error, stack) {
        final message = error is AppFailure ? error.message : null;
        if (kDebugMode) {
          debugPrint('GoMotion fixture load failure: $error');
        }
        return AppErrorState(
          title: 'Demo data unavailable',
          message:
              message ??
              'Bundled demo data could not be loaded. Reinstall the app to '
                  'restore the offline dataset.',
          onRetry: () => ref.invalidate(fixtureBundleProvider),
        );
      },
      data: (bundle) => builder(context, bundle),
    );
  }
}
