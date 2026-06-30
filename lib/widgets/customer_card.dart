import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../utils/app_constants.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing.md),
      padding: EdgeInsets.all(AppConstants.spacing.md),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppConstants.colors.primary.withValues(alpha: 0.1),
            child: Text(
              customer.name[0].toUpperCase(),
              style: TextStyle(
                color: AppConstants.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppConstants.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  customer.mobile,
                  style: TextStyle(
                    color: AppConstants.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (customer.outstandingBalance > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radii.sm),
              ),
              child: Text(
                '${AppConstants.currencySymbol}${customer.outstandingBalance.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppConstants.colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
