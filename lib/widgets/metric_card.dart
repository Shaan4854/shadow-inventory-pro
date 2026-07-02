import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Premium stat card with a left accent bar, matching the React design
/// system's `StatCard` (see `components/ui-kit.tsx`).
///
/// Used for headline dashboard metrics (Total Products, Inventory Value,
/// ...). For the smaller icon-led quick metrics use [QuickMetricCard].
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    this.sub,
    this.accentColor,
    super.key,
  });

  final String label;
  final String value;
  final String? sub;

  /// Left accent bar / tint color. Defaults to the theme primary.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final Color accent = accentColor ?? tokens.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.05), tokens.card),
        borderRadius: BorderRadius.circular(ShadowRadii.xxl),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -20,
            top: -18,
            bottom: -18,
            child: Container(width: 4, color: accent),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.mutedForeground.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.cardForeground,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              if (sub != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  sub!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.mutedForeground,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact icon-led metric card, matching the React Dashboard's "Quick
/// Metrics" row (out of stock / low stock / customers / suppliers).
class QuickMetricCard extends StatelessWidget {
  const QuickMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final Color iconColor = color ?? tokens.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(ShadowRadii.xxl),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: iconColor.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: tokens.cardForeground,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.mutedForeground,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
