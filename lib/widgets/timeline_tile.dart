import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_movement.dart';
import '../models/transaction_type.dart';
import '../utils/app_constants.dart';

class TimelineTile extends StatelessWidget {
  const TimelineTile({required this.movement, super.key});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final bool isIncrease = movement.quantityChange > 0;
    final Color color = isIncrease ? AppConstants.colors.green : AppConstants.colors.red;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(movement.type),
                  color: color,
                  size: 16,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppConstants.colors.border,
              ),
            ],
          ),
          SizedBox(width: AppConstants.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      movement.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${isIncrease ? "+" : ""}${movement.quantityChange}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getTypeLabel(movement.type),
                  style: TextStyle(
                    color: AppConstants.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (movement.reason.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      movement.reason,
                      style: TextStyle(
                        color: AppConstants.colors.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Text(
                  DateFormat('hh:mm a').format(movement.createdAt),
                  style: TextStyle(
                    color: AppConstants.colors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(TransactionType type) {
    return switch (type) {
      TransactionType.purchase => Icons.add_shopping_cart_rounded,
      TransactionType.sale => Icons.sell_rounded,
      TransactionType.salesReturn => Icons.keyboard_return_rounded,
      TransactionType.purchaseReturn => Icons.assignment_return_rounded,
      TransactionType.adjustment => Icons.tune_rounded,
    };
  }

  String _getTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.purchase => 'Purchase',
      TransactionType.sale => 'Sale',
      TransactionType.salesReturn => 'Sales Return',
      TransactionType.purchaseReturn => 'Purchase Return',
      TransactionType.adjustment => 'Adjustment',
    };
  }
}
