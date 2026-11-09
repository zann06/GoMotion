import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

/// The standard page scaffold used by every GoMotion screen.
///
/// Provides consistent safe-area handling, horizontal gutters, an optional large
/// title + subtitle, a scrollable body, and an optional sticky footer for the
/// primary action. The sticky footer keeps the CTA reachable without scrolling,
/// matching the design references.
class AppPage extends StatelessWidget {
  const AppPage({
    required this.body,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.footer,
    this.scrollable = true,
    this.padded = true,
    this.safeBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.autofocusScroll = true,
    super.key,
  });

  /// The page content.
  final Widget body;

  /// Large screen title rendered in the header.
  final String? title;

  /// Supporting line under the title.
  final String? subtitle;

  /// Optional leading control, typically a back button.
  final Widget? leading;

  /// Optional trailing controls in the header.
  final List<Widget>? actions;

  /// Sticky footer, usually a [PrimaryButton].
  final Widget? footer;

  /// Whether to wrap [body] in a scroll view. Disable for full-bleed maps.
  final bool scrollable;

  /// Whether to apply the standard horizontal gutter to the body.
  final bool padded;

  /// Whether to inset the footer for the bottom safe area.
  final bool safeBottom;

  final bool resizeToAvoidBottomInset;

  /// Adds bottom padding so the last element clears the sticky footer.
  final bool autofocusScroll;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || leading != null || actions != null;

    final bodyContent = scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              padded ? AppSpacing.pageGutter : 0,
              0,
              padded ? AppSpacing.pageGutter : 0,
              AppSpacing.xl,
            ),
            child: body,
          )
        : body;

    return Scaffold(
      backgroundColor: AppColors.softWhite,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        bottom: footer == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasHeader)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      padded ? AppSpacing.pageGutter : 0,
                      AppSpacing.md,
                      padded ? AppSpacing.pageGutter : 0,
                      AppSpacing.md,
                    ),
                    child: _Header(
                      title: title,
                      subtitle: subtitle,
                      leading: leading,
                      actions: actions,
                    ),
                  ),
                Expanded(child: bodyContent),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: footer == null
          ? null
          : _StickyFooter(safeBottom: safeBottom, child: footer!),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.title, this.subtitle, this.leading, this.actions});

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null || actions != null)
          Row(
            children: [
              if (leading != null) leading! else const SizedBox(height: 44),
              const Spacer(),
              ...?actions,
            ],
          ),
        if (title != null)
          Semantics(
            header: true,
            child: Text(title!, style: AppTypography.title),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: AppTypography.subtitle),
        ],
      ],
    );
  }
}

/// The sticky footer surface that hosts a primary action.
class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.child, required this.safeBottom});

  final Widget child;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.softWhite,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: SafeArea(
        top: false,
        bottom: safeBottom,
        child: Center(
          // `heightFactor: 1` keeps the footer sized to its content. Without
          // it, Center expands to the full height offered by the Scaffold's
          // bottomNavigationBar slot and collapses the page body to zero.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.sm,
                AppSpacing.pageGutter,
                AppSpacing.sm,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A minimal back affordance with a guaranteed 48dp touch target.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    this.onPressed,
    this.semanticLabel = 'Go back',
    super.key,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Material(
          color: AppColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.lightBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed ?? () => Navigator.of(context).maybePop(),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.deepNavy,
            ),
          ),
        ),
      ),
    );
  }
}
