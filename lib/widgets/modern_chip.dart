import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Visual variant, mirrors `components/ui-kit.tsx`'s `Badge` variants.
enum ModernChipVariant { primary, success, warning, danger, muted }

/// Small pill-shaped label chip used for categories, stock states, etc.
/// Matches the React design system's `Badge` component. Purely
/// presentational — callers decide what text/variant to pass.
class ModernChip extends StatelessWidget {
  const ModernChip({
    required this.label,
    this.variant = ModernChipVariant.muted,
    this.icon,
    super.key,
  });

  final String label;
  final ModernChipVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final Color color = _colorFor(variant, tokens);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ShadowRadii.xxl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(ModernChipVariant variant, ShadowTokens tokens) {
    return switch (variant) {
      ModernChipVariant.primary => tokens.primary,
      ModernChipVariant.success => tokens.chart4,
      ModernChipVariant.warning => tokens.chart5,
      ModernChipVariant.danger => tokens.destructive,
      ModernChipVariant.muted => tokens.mutedForeground,
    };
  }
}
