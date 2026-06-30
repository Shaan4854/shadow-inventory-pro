import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/product_form_sheet.dart';

/// Deep dive screen for product information and history.
class ProductDetailsScreen extends StatelessWidget {
  /// Creates the product details screen.
  const ProductDetailsScreen({
    required this.product,
    super.key,
  });

  /// Product to display.
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('PRODUCT DETAILS'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _handleEdit(context),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: Icon(Icons.delete_outline_rounded, color: AppConstants.colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ProductHero(product: product),
            SizedBox(height: AppConstants.spacing.xl),
            _StockStatus(product: product),
            SizedBox(height: AppConstants.spacing.xl),
            _DetailsGrid(product: product),
            SizedBox(height: AppConstants.spacing.xxl),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.colors.surfaceHigh,
                    ),
                    child: const Text('Stock History'),
                  ),
                ),
                SizedBox(width: AppConstants.spacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('More Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    ProductFormSheet.show(
      context,
      provider: context.read<ProductProvider>(),
      product: product,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete item?'),
          content: Text('Delete "${product.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      if (context.mounted) {
        await context.read<ProductProvider>().deleteProduct(product.id);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radii.xl),
          child: Container(
            height: 200,
            width: double.infinity,
            color: AppConstants.colors.surface,
            child: product.imagePath != null
                ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                : Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
          ),
        ),
        SizedBox(height: AppConstants.spacing.lg),
        Text(
          product.name,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          product.category.isEmpty ? 'General' : product.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConstants.colors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StockStatus extends StatelessWidget {
  const _StockStatus({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final bool isLow = product.stock <= product.alertThreshold;
    final Color color = isLow ? AppConstants.colors.red : AppConstants.colors.green;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing.md,
        vertical: AppConstants.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          isLow ? 'Low Stock' : 'In Stock',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  const _DetailsGrid({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _DetailItem(label: 'Stock', value: '${product.stock}')),
            Expanded(
              child: _DetailItem(
                label: 'Selling Price',
                value: '${AppConstants.currencySymbol}${product.sellPrice}',
              ),
            ),
            Expanded(
              child: _DetailItem(
                label: 'Cost Price',
                value: '${AppConstants.currencySymbol}${product.buyPrice}',
              ),
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacing.md),
        _Divider(),
        _RowItem(label: 'SKU', value: product.sku.isEmpty ? '-' : product.sku),
        const _Divider(),
        _RowItem(label: 'Barcode', value: product.barcode.isEmpty ? '-' : product.barcode),
        const _Divider(),
        _RowItem(label: 'Category', value: product.category.isEmpty ? 'General' : product.category),
        const _Divider(),
        const _RowItem(label: 'Supplier', value: 'Reliable Traders'), // Mock
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppConstants.colors.textMuted,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(color: AppConstants.colors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: AppConstants.colors.border, height: 1);
  }
}
