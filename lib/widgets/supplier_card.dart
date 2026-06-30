import 'package:flutter/material.dart';
import '../models/supplier.dart';
import '../utils/app_constants.dart';

class SupplierCard extends StatelessWidget {
  const SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing.md),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/supplier-details',
          arguments: supplier,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        child: Container(
          padding: EdgeInsets.all(AppConstants.spacing.md),
          decoration: BoxDecoration(
            color: AppConstants.colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radii.lg),
            border: Border.all(color: AppConstants.colors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppConstants.colors.blue.withValues(alpha: 0.1),
                child: Text(
                  supplier.name[0].toUpperCase(),
                  style: TextStyle(
                    color: AppConstants.colors.blue,
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
                      supplier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${supplier.contactPerson} • ${supplier.mobile}',
                      style: TextStyle(
                        color: AppConstants.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (supplier.outstandingBalance > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radii.sm),
                  ),
                  child: Text(
                    '${AppConstants.currencySymbol}${supplier.outstandingBalance.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppConstants.colors.orange,
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
        ),
      ),
    );
  }
}
