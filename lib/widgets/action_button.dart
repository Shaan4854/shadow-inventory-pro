import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Button visual variant, mirrors `components/ui-kit.tsx`'s `Button`.
enum ActionButtonVariant { primary, secondary, outline, ghost, danger }

/// Pill/rounded action button used for primary CTAs (Quick Actions row,
/// "View All" links, etc.), matching the React design system's `Button`.
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ActionButtonVariant.primary,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final _ButtonColors colors = _colorsFor(variant, tokens);

    final Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: colors.elevated ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: colors.border != null
            ? BorderSide(color: colors.border!)
            : BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShadowRadii.lg),
        ),
      ),
      child: child,
    );
  }

  _ButtonColors _colorsFor(ActionButtonVariant variant, ShadowTokens tokens) {
    return switch (variant) {
      ActionButtonVariant.primary => _ButtonColors(
          background: tokens.primary,
          foreground: tokens.primaryForeground,
          elevated: true,
        ),
      ActionButtonVariant.secondary => _ButtonColors(
          background: tokens.secondary,
          foreground: tokens.secondaryForeground,
        ),
      ActionButtonVariant.outline => _ButtonColors(
          background: Colors.transparent,
          foreground: tokens.foreground,
          border: tokens.border,
        ),
      ActionButtonVariant.ghost => _ButtonColors(
          background: Colors.transparent,
          foreground: tokens.foreground,
        ),
      ActionButtonVariant.danger => _ButtonColors(
          background: tokens.destructive,
          foreground: tokens.destructiveForeground,
          elevated: true,
        ),
    };
  }
}

class _ButtonColors {
  _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
    this.elevated = false,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final bool elevated;
}
