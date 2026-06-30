import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    super.key,
  });

  final double subtotal;
  final double discount;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radii.xl)),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          _SummaryRow(label: 'Discount', value: discount, isNegative: true),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Grand Total',
            value: grandTotal,
            isBold: true,
            large: true,
            color: AppConstants.colors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isBold = false,
    this.large = false,
    this.color,
  });

  final String label;
  final double value;
  final bool isNegative;
  final bool isBold;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppConstants.colors.textPrimary : AppConstants.colors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: large ? 16 : 14,
            ),
          ),
          Text(
            '${isNegative ? "-" : ""}${AppConstants.currencySymbol}${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: color ?? (isBold ? AppConstants.colors.textPrimary : AppConstants.colors.textSecondary),
              fontWeight: isBold ? FontWeight.w900 : FontWeight.normal,
              fontSize: large ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
