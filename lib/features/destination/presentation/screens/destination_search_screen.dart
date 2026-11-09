import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/mascot_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_inputs.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/fixture_gate.dart';
import '../../../../domain/entities/fixtures.dart';
import '../../../../domain/repositories/fixture_repository.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../ride/application/ride_controller.dart';

/// Whether the user is choosing a pickup or a destination.
enum DestinationMode { pickup, destination }

/// A local, offline destination picker.
///
/// Search filters the bundled fixture list by name, locality, or category. There
/// is no geocoding and no network: every result is a fixture entry.
class DestinationSearchScreen extends ConsumerStatefulWidget {
  const DestinationSearchScreen({
    this.mode = DestinationMode.destination,
    super.key,
  });

  final DestinationMode mode;

  @override
  ConsumerState<DestinationSearchScreen> createState() =>
      _DestinationSearchScreenState();
}

class _DestinationSearchScreenState
    extends ConsumerState<DestinationSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Picks [location] as the pickup or destination and advances the flow.
  void _choose(FixtureBundle bundle, Location location) {
    final existing = ref.read(rideProvider).ride;

    if (widget.mode == DestinationMode.pickup || existing == null) {
      ref
          .read(rideProvider.notifier)
          .beginDraft(
            pickup: widget.mode == DestinationMode.pickup
                ? location
                : bundle.defaultPickup,
            destination: location,
          );
    } else {
      ref
          .read(rideProvider.notifier)
          .beginDraft(pickup: existing.pickup, destination: location);
    }

    // Replace the search page so Back from vehicle selection returns home
    // rather than landing on a stale search state.
    context.pushReplacementNamed(AppRoutes.vehicleSelectionName);
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.mode == DestinationMode.pickup;
    return AppPage(
      title: isPickup ? 'Choose pickup' : 'Where to?',
      subtitle: 'Demo destinations from the bundled offline dataset',
      leading: const AppBackButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Search demo places',
            hint: 'Name, area, or category',
            controller: _controller,
            prefixIcon: Icons.search_rounded,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            suffix: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.neutralGray,
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FixtureGate(
            loading: const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: AppSkeletonList(itemCount: 4, itemHeight: 64),
            ),
            builder: (context, bundle) => _Results(
              bundle: bundle,
              query: _query,
              onChoose: (location) => _choose(bundle, location),
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.bundle,
    required this.query,
    required this.onChoose,
  });

  final FixtureBundle bundle;
  final String query;
  final ValueChanged<Location> onChoose;

  List<Location> get _matches {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return bundle.locations;
    return [
      for (final location in bundle.locations)
        if (location.name.toLowerCase().contains(normalized) ||
            location.addressLabel.toLowerCase().contains(normalized) ||
            location.category.toLowerCase().contains(normalized))
          location,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = _matches;

    if (matches.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No demo place matches',
        message:
            'Try a different name, area, or category. Every result comes from '
            'the bundled offline dataset.',
        actionLabel: 'Show all demo places',
        onAction: () => onChoose(bundle.locations.first),
        mascot: MascotVariant.error,
      );
    }

    final favorites = ref.watch(favoriteIdsProvider);
    final saved = [
      for (final location in matches)
        if (favorites.contains(location.id)) location,
    ];
    final others = [
      for (final location in matches)
        if (!favorites.contains(location.id)) location,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (saved.isNotEmpty) ...[
          const SectionHeader(title: 'Saved'),
          const SizedBox(height: AppSpacing.xs),
          for (final location in saved) ...[
            _LocationRow(
              location: location,
              isSaved: true,
              onTap: () => onChoose(location),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        if (others.isNotEmpty) ...[
          SectionHeader(title: saved.isEmpty ? 'Demo places' : 'All places'),
          const SizedBox(height: AppSpacing.xs),
          for (final location in others) ...[
            _LocationRow(
              location: location,
              isSaved: false,
              onTap: () => onChoose(location),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.isSaved,
    required this.onTap,
  });

  final Location location;
  final bool isSaved;
  final VoidCallback onTap;

  static const Map<String, IconData> _categoryIcons = {
    'saved': Icons.home_rounded,
    'education': Icons.school_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'transit': Icons.train_rounded,
    'leisure': Icons.park_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: '${location.name}, ${location.addressLabel}',
      child: SelectionRow(
        title: location.name,
        subtitle: location.addressLabel,
        leading: IconWell(
          icon: _categoryIcons[location.category] ?? Icons.place_rounded,
        ),
        trailing: isSaved
            ? const Icon(
                Icons.bookmark_rounded,
                size: 18,
                color: AppColors.primaryIndigo,
              )
            : const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.neutralGray,
              ),
      ),
    );
  }
}
