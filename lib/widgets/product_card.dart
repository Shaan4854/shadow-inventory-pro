import 'dart:io';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/app_constants.dart';

/// Inventory product card matching the original Shadow item style.
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

  /// Called when the card is tapped for editing.
  final VoidCallback onEdit;

  /// Called when delete is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppConstants.radii.xl),
      child: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppConstants.colors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radii.xl),
              border: Border.all(color: AppConstants.colors.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppConstants.spacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ProductImage(product: product),
                  SizedBox(width: AppConstants.spacing.lg),
                  Expanded(
                    child: _ProductDetails(
                      product: product,
                      profit: profit,
                      isOutOfStock: isOutOfStock,
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing.sm),
                  _DeleteButton(onPressed: onDelete),
                ],
              ),
            ),
          ),
          if (isOutOfStock || isLowStock)
            Positioned(
              top: 0,
              right: 0,
              child: _StatusBanner(
                label: isOutOfStock ? 'OUT' : 'LOW',
                icon: isOutOfStock ? Icons.circle : Icons.warning_rounded,
                backgroundColor: isOutOfStock
                    ? AppConstants.colors.red
                    : AppConstants.colors.yellow,
                foregroundColor: isOutOfStock
                    ? AppConstants.colors.onDanger
                    : AppConstants.colors.onAccent,
              ),
            ),
        ],
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
      child: ColoredBox(
        color: AppConstants.colors.surfaceHigh,
        child: SizedBox.square(
          dimension: 64,
          child: imagePath == null || imagePath.isEmpty
              ? Center(
                  child: Text(
                    product.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                )
              : Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Text(
                        product.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.profit,
    required this.isOutOfStock,
  });

  final Product product;
  final double profit;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: AppConstants.spacing.sm),
        Wrap(
          spacing: AppConstants.spacing.xs,
          runSpacing: AppConstants.spacing.xs,
          children: <Widget>[
            _PriceBadge(
              label: 'Buy ${AppConstants.currencySymbol}${product.buyPrice}',
              color: AppConstants.colors.red,
            ),
            _PriceBadge(
              label: 'Sell ${AppConstants.currencySymbol}${product.sellPrice}',
              color: AppConstants.colors.blue,
            ),
            _PriceBadge(
              label: 'Profit ${AppConstants.currencySymbol}$profit',
              color: AppConstants.colors.green,
            ),
          ],
        ),
        SizedBox(height: AppConstants.spacing.sm),
        _StockBadge(product: product, isOutOfStock: isOutOfStock),
      ],
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppConstants.radii.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.sm,
          vertical: AppConstants.spacing.xxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.product,
    required this.isOutOfStock,
  });

  final Product product;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    final Color color = isOutOfStock
        ? AppConstants.colors.red
        : AppConstants.colors.yellow;
    final String label = isOutOfStock
        ? 'Out of Stock'
        : '${product.stock} in stock';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppConstants.radii.pill),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.md,
          vertical: AppConstants.spacing.xxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline_rounded),
      color: AppConstants.colors.red,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: AppConstants.colors.red.withOpacity(0.09),
        side: BorderSide(color: AppConstants.colors.red.withOpacity(0.19)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radii.sm),
        ),
        minimumSize: const Size.square(32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppConstants.radii.xl),
          bottomLeft: Radius.circular(AppConstants.radii.md),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.md,
          vertical: AppConstants.spacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: foregroundColor, size: 10),
            SizedBox(width: AppConstants.spacing.xxs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foregroundColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}