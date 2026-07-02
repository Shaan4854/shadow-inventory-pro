import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import 'modern_chip.dart';
import 'product_form_sheet.dart';

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
    final double margin =
        product.sellPrice > 0 ? (profit / product.sellPrice) * 100 : 0;

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
                  SizedBox(height: AppConstants.spacing.xxs),
                  ModernChip(
                    label: product.category.isEmpty
                        ? 'General'
                        : product.category,
                  ),
                  SizedBox(height: AppConstants.spacing.xxs),
                  Row(
                    children: <Widget>[
                      Text(
                        '${AppConstants.currencySymbol}${product.sellPrice}',
                        style: TextStyle(
                          color: AppConstants.colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.sellPrice > 0) ...<Widget>[
                        SizedBox(width: AppConstants.spacing.sm),
                        Text(
                          '${margin.toStringAsFixed(1)}% margin',
                          style: TextStyle(
                            color: AppConstants.colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
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
                    color: isOutOfStock
                        ? AppConstants.colors.red
                        : AppConstants.colors.green,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(width: AppConstants.spacing.md),
            InkWell(
              onTap: () => _showActions(context),
              borderRadius: BorderRadius.circular(AppConstants.radii.md),
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacing.xs),
                child: Icon(
                  Icons.more_vert,
                  color: AppConstants.colors.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final ProductProvider provider = context.read<ProductProvider>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConstants.colors.backgroundAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).pushNamed(
                    AppRoutes.productDetails,
                    arguments: product,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ProductFormSheet.show(
                    context,
                    provider: provider,
                    product: product,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Duplicate'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ProductFormSheet.show(
                    context,
                    provider: provider,
                    product: product,
                    isDuplicate: true,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded,
                    color: AppConstants.colors.red,),
                title: Text('Delete',
                    style: TextStyle(color: AppConstants.colors.red),),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete();
                },
              ),
              SizedBox(height: AppConstants.spacing.md),
            ],
          ),
        );
      },
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
