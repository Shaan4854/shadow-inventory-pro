import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Section title with an optional trailing action (e.g. "View All"),
/// matching the React Dashboard's recurring section header pattern.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: tokens.foreground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: tokens.foreground,
              side: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ShadowRadii.lg),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: Text(
              actionLabel!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
