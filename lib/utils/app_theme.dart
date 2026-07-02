import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'app_constants.dart';

/// Material 3 dark theme tuned to match the original Shadow visual language.
abstract final class AppTheme {
  const AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppConstants.colors.primary,
      onPrimary: Colors.white,
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
      backgroundColor: AppConstants.colors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: const CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppConstants.colors.surface,
      hintStyle: TextStyle(color: AppConstants.colors.textMuted),
      labelStyle: TextStyle(color: AppConstants.colors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _inputBorder(AppConstants.colors.border),
      enabledBorder: _inputBorder(AppConstants.colors.border),
      focusedBorder: _inputBorder(AppConstants.colors.primary),
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
      selectedColor: AppConstants.colors.primary,
      disabledColor: AppConstants.colors.surfaceHigh,
      labelStyle: TextStyle(color: AppConstants.colors.textSecondary),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
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
    extensions: const <ThemeExtension<dynamic>>[
      ShadowTokens.dark,
    ],
  );

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radii.md),
      borderSide: BorderSide(color: color),
    );
  }
}
