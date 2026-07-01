import 'package:flutter/material.dart';
import '../models/transaction_item.dart';
import '../utils/app_constants.dart';
import 'quantity_stepper.dart';

class CommerceCartItem extends StatelessWidget {
  const CommerceCartItem({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onPriceEdit,
    this.onDiscountEdit,
    this.canEditPrice = true,
    super.key,
  });

  final TransactionItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onPriceEdit;
  final VoidCallback? onDiscountEdit;
  final bool canEditPrice;

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
      child: Column(
        children: [
          Row(
            children: [
              Text(item.productEmoji, style: const TextStyle(fontSize: 24)),
              SizedBox(width: AppConstants.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Unit: ${item.productUnit}',
                      style: TextStyle(
                        color: AppConstants.colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppConstants.colors.red,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionLabel(
                label: 'Price',
                value: '${AppConstants.currencySymbol}${item.priceAtTime}',
                onTap: canEditPrice ? onPriceEdit : null,
              ),
              _ActionLabel(
                label: 'Disc.',
                value: '${AppConstants.currencySymbol}${item.discount}',
                onTap: onDiscountEdit,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      color: AppConstants.colors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  QuantityStepper(
                    value: item.quantity,
                    onChanged: onQuantityChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  color: AppConstants.colors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${item.total.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppConstants.colors.primaryLight,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppConstants.colors.textMuted,
              fontSize: 10,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_rounded,
                  size: 10,
                  color: AppConstants.colors.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
