import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../utils/app_constants.dart';
import '../widgets/status_badge.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({required this.transaction, super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('TRANSACTION DETAILS'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TransactionHeader(transaction: transaction),
            SizedBox(height: AppConstants.spacing.xl),
            _ItemsList(items: transaction.items),
            SizedBox(height: AppConstants.spacing.xl),
            _FinancialSummary(transaction: transaction),
            if (transaction.notes.isNotEmpty) ...[
              SizedBox(height: AppConstants.spacing.xl),
              const Text('Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),),
              SizedBox(height: AppConstants.spacing.xs),
              Text(transaction.notes,
                  style: TextStyle(color: AppConstants.colors.textSecondary),),
            ],
          ],
        ),
      ),
    );
  }
}

class _TransactionHeader extends StatelessWidget {
  const _TransactionHeader({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(type: transaction.type),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a')
                    .format(transaction.createdAt),
                style: TextStyle(
                    color: AppConstants.colors.textMuted, fontSize: 12,),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing.lg),
          Text(
            transaction.entityName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Payment via ${transaction.paymentMethod}',
            style: TextStyle(color: AppConstants.colors.textSecondary),
          ),
          const Divider(height: 32),
          Text(
            'ID: ${transaction.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(
                color: AppConstants.colors.textMuted,
                fontSize: 10,
                fontFamily: 'monospace',),
          ),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items});
  final List<TransactionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ITEMS',
            style: TextStyle(
                fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12,),),
        SizedBox(height: AppConstants.spacing.md),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(item.productEmoji, style: const TextStyle(fontSize: 20)),
                  SizedBox(width: AppConstants.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),),
                        Text(
                          '${item.quantity} x ${AppConstants.currencySymbol}${item.priceAtTime}',
                          style: TextStyle(
                              color: AppConstants.colors.textSecondary,
                              fontSize: 12,),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),),
      ],
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        color: AppConstants.colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: transaction.totalAmount),
          _SummaryRow(
              label: 'Discount', value: transaction.discount, isNegative: true,),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total Amount',
            value: transaction.grandTotal,
            isBold: true,
            color: AppConstants.colors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isNegative = false,
      this.isBold = false,
      this.color,});
  final String label;
  final double value;
  final bool isNegative;
  final bool isBold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color:
                    isBold ? Colors.white : AppConstants.colors.textSecondary,),),
        Text(
          '${isNegative ? "-" : ""}${AppConstants.currencySymbol}${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color ??
                (isBold ? Colors.white : AppConstants.colors.textPrimary),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
