import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../constants/mascot_assets.dart';
import 'app_states.dart';

/// A screen-body wrapper for [AppEmptyState].
///
/// Adds the top rhythm the design system expects between a page header and its
/// content, so individual screens do not repeat spacing magic numbers.
class EmptyStateBody extends StatelessWidget {
  const EmptyStateBody({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.mascot,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional mascot illustration for the empty state.
  final MascotVariant? mascot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: AppEmptyState(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        mascot: mascot,
      ),
    );
  }
}
