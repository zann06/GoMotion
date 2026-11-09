import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/empty_state_body.dart';

/// The fictional demo profile, wallet, and settings entry point.
///
/// Phase 8 wires the wallet, favourites, and settings. Until then this remains a
/// working placeholder that does not imply real account data.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Your profile',
      subtitle: 'Manage your GoMotion demo experience',
      body: EmptyStateBody(
        icon: Icons.person_outline_rounded,
        title: 'Demo profile loading next',
        message:
            'Your fictional demo wallet, saved places, and settings are '
            'delivered in a later phase.',
      ),
    );
  }
}
