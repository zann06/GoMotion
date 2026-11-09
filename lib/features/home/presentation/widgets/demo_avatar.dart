import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../domain/entities/fixtures.dart';

/// Resolves the demo profile, used for greetings and wallet display.
///
/// Until fixtures resolve this returns null so callers can show a skeleton
/// rather than a flickering placeholder name.
final demoUserProvider = Provider<DemoUser?>((ref) {
  final async = ref.watch(fixtureBundleProvider);
  return async.maybeWhen(data: (bundle) => bundle.demoUser, orElse: () => null);
});

/// The demo profile avatar with a tonal fallback.
///
/// Uses the bundled local avatar; if it is missing the avatar degrades to a
/// tinted initial so the UI never shows a broken image box.
class DemoAvatar extends StatelessWidget {
  const DemoAvatar({this.size = 44, this.asset, this.name, super.key});

  final double size;
  final String? asset;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.isEmpty)
        ? 'G'
        : name!.characters.first.toUpperCase();

    return Semantics(
      label: name == null ? 'Demo profile avatar' : 'Avatar for $name',
      image: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: asset == null
              ? _Fallback(initial: initial, size: size)
              : Image.asset(
                  asset!,
                  fit: BoxFit.cover,
                  // Local bundled asset, so this is a synchronous decode; the
                  // error builder only guards against a malformed bundle.
                  errorBuilder: (_, _, _) =>
                      _Fallback(initial: initial, size: size),
                ),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.indigoTint),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.itemTitle.copyWith(
            color: AppColors.primaryIndigo,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}

/// The greeting header shown at the top of the home screen.
class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(demoUserProvider);
    final motion = ref.watch(reduceMotionProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user == null
                    ? 'Good afternoon'
                    : '${_greeting()}, ${user.firstName}',
                style: AppTypography.display,
              ),
              const SizedBox(height: AppSpacing.xxs),
              const Text('Your city, your way', style: AppTypography.subtitle),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: motion.resolve(AppDuration.enter),
          child: user == null
              ? const SizedBox.shrink()
              : Semantics(
                  button: true,
                  label: 'Open profile',
                  child: GestureDetector(
                    onTap: () => context.goNamed(AppRoutes.profileName),
                    child: DemoAvatar(
                      key: const ValueKey('home-avatar'),
                      size: 46,
                      asset: user.avatarAsset.isEmpty
                          ? null
                          : 'assets/images/${user.avatarAsset}',
                      name: user.displayName,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// A deterministic part-of-day greeting derived from the local hour.
  ///
  /// Local-only, so it never implies a server time sync.
  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}
