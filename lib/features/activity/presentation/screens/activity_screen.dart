import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/empty_state_body.dart';

/// Unified history of simulated journeys.
///
/// Phase 5 populates this with real records from the activity repository. Until
/// then it states plainly that nothing has happened, rather than fabricating
/// history the simulation never produced.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Your activity',
      subtitle: 'A history of simulated journeys',
      body: EmptyStateBody(
        icon: Icons.receipt_long_outlined,
        title: 'No demo journeys yet',
        message:
            'Completed rides, food orders, and parcel deliveries appear here '
            'once you finish a simulated journey.',
      ),
    );
  }
}
