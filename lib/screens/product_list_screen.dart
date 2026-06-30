import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_inventory.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final List<Product> products = provider.filteredProducts;

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('ALL PRODUCTS'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppConstants.spacing.page,
              AppConstants.spacing.md,
              AppConstants.spacing.page,
              AppConstants.spacing.xs,
            ),
            child: Column(
              children: [
                SearchBarWidget(
                  onChanged: provider.search,
                  focusNode: _searchFocusNode,
                ),
                SizedBox(height: AppConstants.spacing.md),
                CategoryFilterBar(
                  selectedFilter: provider.selectedFilter,
                  onFilterSelected: provider.setFilter,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppConstants.durations.normal,
              child: products.isEmpty
                  ? const EmptyInventory()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        AppConstants.spacing.page,
                        AppConstants.spacing.md,
                        AppConstants.spacing.page,
                        AppConstants.spacing.page,
                      ),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 1),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          profit: provider.unitProfit(product),
                          isLowStock: provider.isLowStock(product),
                          isOutOfStock: provider.isOutOfStock(product),
                          onEdit: () => _handleDetails(context, product),
                          onDelete: () => _confirmDelete(context, provider, product),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDetails(BuildContext context, Product product) {
    _searchFocusNode.unfocus();
    Navigator.of(context).pushNamed(
      AppRoutes.productDetails,
      arguments: product,
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductProvider provider, Product product) async {
    _searchFocusNode.unfocus();
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
      await provider.deleteProduct(product.id);
    }
  }
}
