import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Inline, static alert chip used at the top of the Dashboard to surface
/// out-of-stock / low-stock counts, matching the React Dashboard's
/// left-accent-bar alert pills. Distinct from [AlertBanner], which is a
/// transient full-width banner tied to form validation/error state.
class StockAlertChip extends StatelessWidget {
  const StockAlertChip({
    required this.message,
    required this.icon,
    required this.color,
    super.key,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.06), tokens.card),
        borderRadius: BorderRadius.circular(ShadowRadii.lg),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.2)),
          right: BorderSide(color: color.withValues(alpha: 0.2)),
          bottom: BorderSide(color: color.withValues(alpha: 0.2)),
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
