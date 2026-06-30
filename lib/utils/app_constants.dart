import 'package:flutter/material.dart';

/// Centralized app constants derived from the original Shadow HTML design.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Shadow Inventory Pro';
  static const String shortAppName = 'Shadow';
  static const String appSubtitle = 'Inventory';

  static const String currencySymbol = '৳';
  static const int defaultLowStockAlert = 5;
  static const int highStockThreshold = 20;
  static const int lowStockFilterThreshold = 5;
  static const double maxContentWidth = 430;

  static const List<String> productCategories = <String>[
    'General',
    'Electronics',
    'Accessories',
    'Clothing',
    'Footwear',
    'Home',
    'Other',
  ];

  static const List<String> fallbackEmojis = <String>[
    '📦',
    '🛍️',
    '🎁',
    '⚡',
    '🔌',
    '📱',
    '💻',
    '🎧',
    '👕',
    '👟',
  ];

  static const AppColors colors = AppColors();
  static const AppSpacing spacing = AppSpacing();
  static const AppDurations durations = AppDurations();
  static const AppRadii radii = AppRadii();
}

class AppColors {
  const AppColors();

  final Color background = const Color(0xFF0A0A0F);
  final Color backgroundAlt = const Color(0xFF111118);
  final Color surface = const Color(0xFF1A1A24);
  final Color surfaceHigh = const Color(0xFF22222F);
  final Color border = const Color(0xFF2A2A38);

  final Color gold = const Color(0xFFF5C842);
  final Color goldDark = const Color(0xFFE0B030);
  final Color goldLight = const Color(0xFFFFF3B0);

  final Color blue = const Color(0xFF4A9EFF);
  final Color blueDark = const Color(0xFF1A6FD4);
  final Color red = const Color(0xFFFF4D4D);
  final Color green = const Color(0xFF3DDB6A);
  final Color yellow = const Color(0xFFFFE066);

  final Color textPrimary = const Color(0xFFF0F0F0);
  final Color textSecondary = const Color(0xFFA0A0B0);
  final Color textMuted = const Color(0xFF6A6A80);
  final Color onAccent = Colors.black;
  final Color onDanger = Colors.white;
}

class AppSpacing {
  const AppSpacing();

  final double xxs = 2;
  final double xs = 4;
  final double sm = 6;
  final double md = 8;
  final double lg = 10;
  final double xl = 12;
  final double xxl = 14;
  final double page = 16;
  final double fabMargin = 18;
  final double bottomListPadding = 90;
}

class AppRadii {
  const AppRadii();

  final double sm = 6;
  final double md = 10;
  final double lg = 12;
  final double xl = 14;
  final double sheet = 22;
  final double pill = 20;
}

class AppDurations {
  const AppDurations();

  final Duration fast = const Duration(milliseconds: 150);
  final Duration normal = const Duration(milliseconds: 250);
  final Duration sheet = const Duration(milliseconds: 320);
  final Duration alert = const Duration(milliseconds: 350);
  final Duration alertVisible = const Duration(milliseconds: 3500);
}