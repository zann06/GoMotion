import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/reduced_motion_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../core/widgets/schematic_map.dart';
import '../../application/active_journey_provider.dart';
import '../widgets/demo_avatar.dart';

/// The home dashboard: greeting, destination entry point, demo map, service
/// shortcuts, and popular nearby destinations.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPage(
      padded: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeGreeting(),
          _ActiveJourneyBanner(),
          SizedBox(height: AppSpacing.lg),
          _JourneyCard(),
          SizedBox(height: AppSpacing.md),
          _HomeMap(),
          SizedBox(height: AppSpacing.xl),
          _ServiceShortcuts(),
          SizedBox(height: AppSpacing.xl),
          _PopularNearby(),
          SizedBox(height: AppSpacing.md),
          _DemoDisclosure(),
        ],
      ),
    );
  }
}

/// A resume card shown when a demo journey is still in progress.
///
/// Tapping reopens the exact live screen rather than letting a fresh draft
/// discard the journey the user already started.
class _ActiveJourneyBanner extends ConsumerWidget {
  const _ActiveJourneyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journey = ref.watch(activeJourneyProvider);
    if (journey == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: AppCard(
        onTap: () => context.push(journey.location),
        semanticLabel:
            '${journey.kind.label} in progress: ${journey.title}. '
            '${journey.actionLabel}',
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.indigoTint,
                borderRadius: AppRadius.tile,
              ),
              child: Icon(
                _iconFor(journey.kind),
                color: AppColors.primaryIndigo,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${journey.kind.label} in progress',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    journey.title,
                    style: AppTypography.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    journey.detail,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TonalButtonInline(
              label: journey.actionLabel,
              onPressed: () => context.push(journey.location),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(ActiveJourneyKind kind) => switch (kind) {
    ActiveJourneyKind.ride => Icons.directions_car_filled_rounded,
    ActiveJourneyKind.food => Icons.restaurant_rounded,
    ActiveJourneyKind.send => Icons.inventory_2_rounded,
  };
}

/// The gradient "Your next journey" card containing the destination entry.
///
/// Tapping anywhere on the search field or the card opens destination search,
/// which is the single obvious next action on this screen.
class _JourneyCard extends ConsumerWidget {
  const _JourneyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    final card = Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.hero,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your next journey', style: AppTypography.onGradientTitle),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Where would you like to go?',
            style: AppTypography.onGradientBody,
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            button: true,
            label: 'Search destination',
            child: Material(
              color: AppColors.white,
              borderRadius: AppRadius.button,
              child: InkWell(
                borderRadius: AppRadius.button,
                onTap: () => context.pushNamed(AppRoutes.destinationSearchName),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.neutralGray,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Search destination',
                          style: AppTypography.bodyMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Reduced motion must never hide content: skip the entrance animation
    // entirely instead of parking the controller on its invisible first frame.
    if (motion.enabled) return card;

    return card
        .animate()
        .fadeIn(duration: AppDuration.enter)
        .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
  }
}

/// The illustrated demo map with popular destination pins.
class _HomeMap extends ConsumerWidget {
  const _HomeMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FixtureGate(
      loading: const _MapPlaceholder(),
      builder: (context, bundle) {
        final popular = bundle.popularLocations.take(3).toList();
        return SchematicMap(
          height: 190,
          origin: bundle.defaultPickup.point,
          destination: popular.isEmpty ? null : popular.first.point,
          route: popular.isEmpty
              ? const []
              : [bundle.defaultPickup.point, popular.first.point],
        );
      },
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: const BoxDecoration(
        color: AppColors.mapGround,
        borderRadius: AppRadius.card,
      ),
    );
  }
}

/// The four service shortcuts.
///
/// Ride, Food, and Send are functional flows; Rewards opens the rewards tab.
class _ServiceShortcuts extends ConsumerWidget {
  const _ServiceShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = ref.watch(reduceMotionProvider);
    final active = ref.watch(activeJourneyProvider);

    // A service tile resumes its live journey instead of starting over.
    String locationFor(ActiveJourneyKind kind, String fallback) =>
        active?.kind == kind ? active!.location : fallback;

    final services = <_Service>[
      _Service(
        label: 'Ride',
        icon: Icons.directions_car_filled_rounded,
        color: AppColors.primaryIndigo,
        onTap: () => context.push(
          locationFor(ActiveJourneyKind.ride, AppRoutes.destinationSearch),
        ),
      ),
      _Service(
        label: 'Food',
        icon: Icons.restaurant_rounded,
        color: AppColors.electricBlue,
        onTap: () =>
            context.push(locationFor(ActiveJourneyKind.food, AppRoutes.food)),
      ),
      _Service(
        label: 'Send',
        icon: Icons.inventory_2_rounded,
        color: AppColors.violet,
        onTap: () =>
            context.push(locationFor(ActiveJourneyKind.send, AppRoutes.send)),
      ),
      _Service(
        label: 'Rewards',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.deepNavy,
        onTap: () => context.goNamed(AppRoutes.rewardsName),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Explore services'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final (index, service) in services.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ServiceTile(
                  service: service,
                  animationDuration: motion.resolve(AppDuration.enter),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

@immutable
class _Service {
  const _Service({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.animationDuration});

  final _Service service;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      onTap: service.onTap,
      semanticLabel: '${service.label} service',
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: service.color,
              borderRadius: AppRadius.tile,
            ),
            child: Icon(service.icon, color: AppColors.white, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            service.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.deepNavy,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Chooses the most popular nearby destination, per the home reference.
class _PopularNearby extends ConsumerWidget {
  const _PopularNearby();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FixtureGate(
      loading: const SizedBox(height: 92),
      builder: (context, bundle) {
        final popular = bundle.popularLocations.take(2).toList();
        if (popular.isEmpty) {
          return const AppCard(
            child: Text(
              'No demo destinations are bundled yet.',
              style: AppTypography.bodyMuted,
            ),
          );
        }
        final names = popular.map((l) => l.name).join('  ·  ');
        return AppCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Popular nearby',
                      style: AppTypography.itemTitle,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(names, style: AppTypography.bodyMuted),
                  ],
                ),
              ),
              TonalButtonInline(
                label: 'Pick',
                onPressed: () =>
                    context.pushNamed(AppRoutes.destinationSearchName),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A compact pill action used inside list cards.
class TonalButtonInline extends StatelessWidget {
  const TonalButtonInline({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.indigoTint,
        borderRadius: AppRadius.chip,
        child: InkWell(
          borderRadius: AppRadius.chip,
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 64),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(label.toUpperCase(), style: AppTypography.pill),
          ),
        ),
      ),
    );
  }
}

/// A permanent honesty notice that this app is a simulation.
class _DemoDisclosure extends StatelessWidget {
  const _DemoDisclosure();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.neutralGray),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Demo simulation — works offline',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
