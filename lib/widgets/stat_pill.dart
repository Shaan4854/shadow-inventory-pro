import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

/// Compact statistic pill used in the Shadow inventory header.
class StatPill extends StatelessWidget {
  /// Creates a stat pill with a value, label, and accent color.
  const StatPill({
    required this.value,
    required this.label,
    required this.accentColor,
    super.key,
  });

  /// Main statistic value.
  final String value;

  /// Small descriptive label.
  final String label;

  /// Color used for the value text.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.md),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.xs,
          vertical: AppConstants.spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppConstants.spacing.xxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppConstants.colors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
