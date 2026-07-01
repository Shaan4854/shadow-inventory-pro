import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class TransactionSummary extends StatelessWidget {
  const TransactionSummary({
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.grandTotal,
    super.key,
  });

  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final double discount;
  final double tax;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppConstants.radii.xl)),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Items', value: '$itemCount'),
              _Stat(label: 'Total Qty', value: '$totalQuantity'),
              _Stat(
                label: 'Subtotal',
                value: '${AppConstants.currencySymbol}${subtotal.toStringAsFixed(0)}',
              ),
            ],
          ),
          const Divider(height: 24),
          _SummaryRow(label: 'Discount', value: discount, isNegative: true),
          _SummaryRow(label: 'Tax', value: tax),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${AppConstants.currencySymbol}${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppConstants.colors.primaryLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                TextStyle(color: AppConstants.colors.textMuted, fontSize: 10),),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  final String label;
  final double value;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppConstants.colors.textMuted, fontSize: 12),),
          Text(
            '${isNegative ? "-" : ""}${AppConstants.currencySymbol}${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: isNegative
                  ? AppConstants.colors.red
                  : AppConstants.colors.textPrimary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
