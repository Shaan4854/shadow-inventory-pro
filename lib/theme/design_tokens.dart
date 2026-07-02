import 'package:flutter/material.dart';

/// Design tokens ported 1:1 from the React reference project's
/// `app/globals.css`. Values are locked to the design spec — do not
/// re-derive or "improve" them. New/modified widgets should read colors
/// and radii from here (via [ShadowTokens.of]) instead of hardcoding hex.
@immutable
class ShadowTokens extends ThemeExtension<ShadowTokens> {
  const ShadowTokens({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;

  /// Chart palette in declaration order — mirrors `--chart-1..5`.
  List<Color> get chartColors => <Color>[chart1, chart2, chart3, chart4, chart5];

  /// Convenience accessor. Falls back to [light] if no extension is
  /// registered on the current [ThemeData] (should not happen once wired
  /// into `AppTheme`).
  static ShadowTokens of(BuildContext context) {
    return Theme.of(context).extension<ShadowTokens>() ?? light;
  }

  static const ShadowTokens light = ShadowTokens(
    background: Color(0xFFFAFBFC),
    foreground: Color(0xFF0F172A),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0F172A),
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF3F4F6),
    secondaryForeground: Color(0xFF374151),
    muted: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF6B7280),
    accent: Color(0xFF06B6D4),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    input: Color(0xFFF9FAFB),
    chart1: Color(0xFF3B82F6),
    chart2: Color(0xFFEC4899),
    chart3: Color(0xFF8B5CF6),
    chart4: Color(0xFF10B981),
    chart5: Color(0xFFF59E0B),
  );

  static const ShadowTokens dark = ShadowTokens(
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF1F5F9),
    card: Color(0xFF1E2139),
    cardForeground: Color(0xFFF1F5F9),
    primary: Color(0xFF60A5FA),
    primaryForeground: Color(0xFF0F172A),
    secondary: Color(0xFF374151),
    secondaryForeground: Color(0xFFF3F4F6),
    muted: Color(0xFF2D3748),
    mutedForeground: Color(0xFF9CA3AF),
    accent: Color(0xFF22D3EE),
    accentForeground: Color(0xFF0F172A),
    destructive: Color(0xFFF87171),
    destructiveForeground: Color(0xFF0F172A),
    border: Color(0xFF2D3748),
    input: Color(0xFF1E2139),
    chart1: Color(0xFF60A5FA),
    chart2: Color(0xFFF472B6),
    chart3: Color(0xFFA78BFA),
    chart4: Color(0xFF34D399),
    chart5: Color(0xFFFBBF24),
  );

  @override
  ShadowTokens copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? chart1,
    Color? chart2,
    Color? chart3,
    Color? chart4,
    Color? chart5,
  }) {
    return ShadowTokens(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      chart1: chart1 ?? this.chart1,
      chart2: chart2 ?? this.chart2,
      chart3: chart3 ?? this.chart3,
      chart4: chart4 ?? this.chart4,
      chart5: chart5 ?? this.chart5,
    );
  }

  @override
  ShadowTokens lerp(ThemeExtension<ShadowTokens>? other, double t) {
    if (other is! ShadowTokens) return this;
    return ShadowTokens(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground: Color.lerp(
          destructiveForeground, other.destructiveForeground, t,)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      chart1: Color.lerp(chart1, other.chart1, t)!,
      chart2: Color.lerp(chart2, other.chart2, t)!,
      chart3: Color.lerp(chart3, other.chart3, t)!,
      chart4: Color.lerp(chart4, other.chart4, t)!,
      chart5: Color.lerp(chart5, other.chart5, t)!,
    );
  }
}

/// Radius scale — mirrors `--radius-sm..2xl` from `globals.css`.
abstract final class ShadowRadii {
  const ShadowRadii._();

  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;

  /// Default card radius used across the React design system.
  static const double card = 12;
}

/// Motion timings — mirrors the `fadeInUp` / `slideIn*` / `scaleIn`
/// keyframes and the global 300ms transition in `globals.css`.
abstract final class ShadowMotion {
  const ShadowMotion._();

  static const Duration transition = Duration(milliseconds: 300);
  static const Duration fadeUp = Duration(milliseconds: 500);
  static const Duration slideIn = Duration(milliseconds: 500);
  static const Duration scaleIn = Duration(milliseconds: 300);

  static const Curve fadeUpCurve = Curves.easeOut;
  static const Curve slideInCurve = Curves.easeOut;
  static const Curve scaleInCurve = Curves.easeOut;

  static const double fadeUpOffset = 12;
  static const double slideInOffset = 20;
  static const double scaleInFrom = 0.95;
}
