import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 4px-based spacing scale from the approved design system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppTheme {
  AppTheme._();

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.paddyGreen,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.paddyGreen,
        onPrimary: AppColors.riceHusk,
        primaryContainer: AppColors.paddyGreenContainer,
        onPrimaryContainer: AppColors.paddyGreenOnContainer,
        secondary: AppColors.turmericGold,
        onSecondary: AppColors.soilInk,
        secondaryContainer: AppColors.turmericGoldContainer,
        onSecondaryContainer: AppColors.turmericGoldOnContainer,
        tertiary: AppColors.monsoonTeal,
        onTertiary: AppColors.riceHusk,
        tertiaryContainer: AppColors.monsoonTealContainer,
        onTertiaryContainer: AppColors.monsoonTealOnContainer,
        error: AppColors.alertRed,
        onError: Colors.white,
        errorContainer: AppColors.alertRedContainer,
        onErrorContainer: AppColors.alertRedOnContainer,
        surface: AppColors.riceHusk,
        onSurface: AppColors.soilInk,
        outline: AppColors.soilInkSoft,
        outlineVariant: AppColors.hairline,
      );

  // NOTE: font family intentionally left as the platform default (not Noto
  // Sans) for now. The design system calls for Noto Sans for its matching
  // Sinhala/Tamil companions, but wiring that up via google_fonts would
  // fetch font files over the network on first use — unreliable for
  // smallholder farmers on poor rural connectivity. Sizes/weights below
  // match the approved scale exactly; swap in bundled Noto Sans font
  // assets (not a runtime-fetched dependency) when localization work
  // begins.
  static final TextTheme _textTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 32,
      height: 40 / 32,
      fontWeight: FontWeight.w600,
      color: AppColors.soilInk,
    ),
    headlineMedium: const TextStyle(
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
      color: AppColors.soilInk,
    ),
    headlineSmall: const TextStyle(
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      color: AppColors.soilInk,
    ),
    titleLarge: const TextStyle(
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w500,
      color: AppColors.soilInk,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
      color: AppColors.soilInk,
    ),
    titleSmall: const TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: AppColors.soilInk,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.soilInk,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: AppColors.soilInkSoft,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
      color: AppColors.soilInkSoft,
    ),
    labelLarge: const TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.soilInk,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: AppColors.soilInk,
    ),
    labelSmall: const TextStyle(
      fontSize: 11,
      height: 16 / 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      color: AppColors.soilInkSoft,
    ),
  );

  static ThemeData get light {
    const OutlinedBorder pillShape = StadiumBorder();
    final OutlineInputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.soilInkSoft, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.riceHusk,
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paddyGreenContainer,
        foregroundColor: AppColors.paddyGreenOnContainer,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          color: AppColors.paddyGreenOnContainer,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        indicatorColor: AppColors.paddyGreenContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return _textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.paddyGreen : AppColors.soilInkSoft,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.paddyGreen : AppColors.soilInkSoft,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.paddyGreen,
          foregroundColor: AppColors.riceHusk,
          textStyle: _textTheme.labelLarge,
          shape: pillShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paddyGreen,
          side: const BorderSide(color: AppColors.soilInkSoft),
          textStyle: _textTheme.labelLarge,
          shape: pillShape,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.paddyGreen,
          textStyle: _textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paddyGreenContainer,
        labelStyle: _textTheme.labelMedium?.copyWith(
          color: AppColors.paddyGreenOnContainer,
        ),
        shape: pillShape,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        labelStyle: _textTheme.bodyMedium,
        hintStyle: _textTheme.bodyMedium,
        helperStyle: _textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: AppSpacing.md - AppSpacing.xs,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.paddyGreen, width: 2),
        ),
      ),
    );
  }
}
