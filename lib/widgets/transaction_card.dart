import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/app_constants.dart';
import 'status_badge.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    required this.transaction,
    this.onTap,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.spacing.md),
      color: AppConstants.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        side: BorderSide(color: AppConstants.colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacing.page),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.entityName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a')
                            .format(transaction.createdAt),
                        style: TextStyle(
                          color: AppConstants.colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(type: transaction.type),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transaction.items.length} items',
                    style: TextStyle(color: AppConstants.colors.textSecondary),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${transaction.grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppConstants.colors.primaryLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
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
