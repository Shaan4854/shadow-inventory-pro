import 'package:flutter/material.dart';

import 'app_constants.dart';

/// Material 3 dark theme tuned to match the original Shadow visual language.
abstract final class AppTheme {
  const AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppConstants.colors.gold,
      onPrimary: Colors.black,
      secondary: AppConstants.colors.blue,
      onSecondary: AppConstants.colors.textPrimary,
      error: AppConstants.colors.red,
      surface: AppConstants.colors.surface,
      onSurface: AppConstants.colors.textPrimary,
    ),
    scaffoldBackgroundColor: AppConstants.colors.background,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.colors.background,
      foregroundColor: AppConstants.colors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppConstants.colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radii.xl),
        side: BorderSide(color: AppConstants.colors.border),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppConstants.colors.gold,
      foregroundColor: Colors.black,
      elevation: 8,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.colors.surface,
      hintStyle: TextStyle(color: AppConstants.colors.textMuted),
      labelStyle: TextStyle(color: AppConstants.colors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: _inputBorder(AppConstants.colors.border),
      enabledBorder: _inputBorder(AppConstants.colors.border),
      focusedBorder: _inputBorder(AppConstants.colors.gold),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppConstants.colors.backgroundAlt,
      modalBackgroundColor: AppConstants.colors.backgroundAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppConstants.colors.surface,
      selectedColor: AppConstants.colors.gold,
      disabledColor: AppConstants.colors.surfaceHigh,
      labelStyle: TextStyle(color: AppConstants.colors.textSecondary),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      side: BorderSide(color: AppConstants.colors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radii.pill),
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: AppConstants.colors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppConstants.colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: AppConstants.colors.textPrimary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: AppConstants.colors.textSecondary,
        fontSize: 12,
      ),
      labelSmall: TextStyle(
        color: AppConstants.colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radii.md),
      borderSide: BorderSide(color: color),
    );
  }
}
