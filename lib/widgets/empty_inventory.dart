import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

/// Empty state shown when no inventory items match the current view.
class EmptyInventory extends StatelessWidget {
  /// Creates the Shadow-style empty inventory message.
  const EmptyInventory({
    this.message = 'No items yet.\nTap + to add your first item!',
    super.key,
  });

  /// Message shown below the icon.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.page,
          vertical: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '📭',
              style: TextStyle(
                fontSize: 56,
                color: AppConstants.colors.textMuted,
              ),
            ),
            SizedBox(height: AppConstants.spacing.xxl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.colors.textMuted,
                    height: 1.7,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
