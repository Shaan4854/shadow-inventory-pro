import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/app_constants.dart';

/// Inventory product card matching the updated Shadow design.
class ProductCard extends StatelessWidget {
  /// Creates a product card.
  const ProductCard({
    required this.product,
    required this.profit,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// Product to display.
  final Product product;

  /// Precomputed unit profit supplied by the state layer.
  final double profit;

  /// Whether the product should show the low-stock state.
  final bool isLowStock;

  /// Whether the product should show the out-of-stock state.
  final bool isOutOfStock;

  /// Called when the card is tapped for editing or details.
  final VoidCallback onEdit;

  /// Called when delete is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacing.md),
        child: Row(
          children: <Widget>[
            _ProductImage(product: product),
            SizedBox(width: AppConstants.spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.category.isEmpty ? 'General' : product.category,
                    style: TextStyle(color: AppConstants.colors.textMuted, fontSize: 12),
                  ),
                  Text(
                    '${AppConstants.currencySymbol}${product.sellPrice}',
                    style: TextStyle(color: AppConstants.colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${product.stock}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isOutOfStock ? 'Out of Stock' : 'In Stock',
                  style: TextStyle(
                    color: isOutOfStock ? AppConstants.colors.red : AppConstants.colors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(width: AppConstants.spacing.md),
            Icon(Icons.more_vert, color: AppConstants.colors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final String? imagePath = product.imagePath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radii.md),
      child: Container(
        height: 48,
        width: 48,
        color: AppConstants.colors.surfaceHigh,
        child: imagePath == null || imagePath.isEmpty
            ? Center(
                child: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
