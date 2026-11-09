import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Builds the GoMotion [ThemeData].
///
/// The product is light-theme only by design: the palette (soft white ground,
/// white cards, navy text) is the brand. `ThemeMode` is still honoured for
/// system brightness so text remains legible if a user forces dark mode at the
/// OS level.
abstract final class AppTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryIndigo,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryIndigo,
          onPrimary: AppColors.white,
          secondary: AppColors.electricBlue,
          onSecondary: AppColors.white,
          tertiary: AppColors.violet,
          surface: AppColors.white,
          onSurface: AppColors.deepNavy,
          onSurfaceVariant: AppColors.neutralGray,
          error: AppColors.error,
          onError: AppColors.white,
          outline: AppColors.lightBorder,
          outlineVariant: AppColors.lightBorder,
          surfaceContainerLowest: AppColors.white,
          surfaceContainerLow: AppColors.softWhite,
          surfaceContainer: AppColors.softWhite,
        );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.softWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.softWhite,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.deepNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.itemTitle,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.section.copyWith(fontSize: 18),
        contentTextStyle: AppTypography.bodyMuted,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryIndigo,
        linearTrackColor: AppColors.skeleton,
        circularTrackColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        hintStyle: AppTypography.bodyMuted,
        labelStyle: AppTypography.caption,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.primaryIndigo,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryIndigo,
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
          textStyle: AppTypography.itemTitle,
        ),
      ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(scheme),
      visualDensity: VisualDensity.standard,
      // Ripple and highlight are replaced by the app's own press feedback so
      // motion stays consistent and reduced-motion aware.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      // iOS and macOS already default to the platform Cupertino transition, so
      // only Android needs an explicit builder for the brand's forward fade.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return const TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.title,
      headlineSmall: AppTypography.title,
      titleLarge: AppTypography.section,
      titleMedium: AppTypography.itemTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.bodyMuted,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.caption,
      labelSmall: AppTypography.pill,
    );
  }
}
