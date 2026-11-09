import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/empty_state_body.dart';

/// Demo rewards and local unlocks.
///
/// Phase 8 wires the rewards ledger. The screen currently explains the empty
/// state honestly so no unreachable controls are shipped.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Rewards',
      subtitle: 'Fictional demo points and badges',
      body: EmptyStateBody(
        icon: Icons.workspace_premium_outlined,
        title: 'Rewards are coming online',
        message:
            'Complete simulated journeys to collect fictional demo points and '
            'unlock demo badges.',
      ),
    );
  }
}
