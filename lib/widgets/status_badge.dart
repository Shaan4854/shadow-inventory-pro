import 'package:flutter/material.dart';
import '../models/transaction_type.dart';
import '../utils/app_constants.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.type, super.key});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (type) {
      TransactionType.purchase => AppConstants.colors.blue,
      TransactionType.sale => AppConstants.colors.green,
      TransactionType.salesReturn => AppConstants.colors.orange,
      TransactionType.purchaseReturn => AppConstants.colors.purple,
      TransactionType.adjustment => AppConstants.colors.yellow,
    };

    final String label = switch (type) {
      TransactionType.purchase => 'PURCHASE',
      TransactionType.sale => 'SALE',
      TransactionType.salesReturn => 'SALES RETURN',
      TransactionType.purchaseReturn => 'PURCHASE RETURN',
      TransactionType.adjustment => 'ADJUSTMENT',
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing.sm,
        vertical: AppConstants.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
