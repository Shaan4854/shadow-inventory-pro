import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_inventory.dart';
import '../widgets/metric_card.dart';

/// Full product catalog: search, category + stock filters, and the
/// reusable [ProductCard] list. Mobile-first counterpart of the React
/// Products page (`app/products/page.tsx`), whose desktop data table is
/// reflowed here into the existing card list rather than forced into a
/// horizontally-scrolling table.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FocusNode _searchFocusNode = FocusNode();

  /// Category selected in the (new, UI-only) category chip row. This is
  /// purely a display filter layered on top of `provider.filteredProducts`
  /// — it does not touch `ProductProvider` state, mirroring the existing
  /// local-filter pattern already used by `TransactionsScreen`.
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final ProductProvider provider = context.watch<ProductProvider>();
    final List<Product> baseProducts = provider.filteredProducts;
    final List<Product> products = _selectedCategory == 'All'
        ? baseProducts
        : baseProducts
            .where((Product p) => p.category == _selectedCategory)
            .toList();

    final List<String> categories = <String>[
      'All',
      ...<String>{
        for (final Product p in provider.products)
          if (p.category.isNotEmpty) p.category,
      },
    ];

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('PRODUCTS'),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: AppConstants.spacing.page),
            child: IconButton.filled(
              onPressed: () =>
                  ProductFormSheet.show(context, provider: provider),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Product',
              style: IconButton.styleFrom(
                backgroundColor: tokens.primary,
                foregroundColor: tokens.primaryForeground,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppConstants.spacing.page,
              AppConstants.spacing.md,
              AppConstants.spacing.page,
              AppConstants.spacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${provider.totalItems} products · ${provider.totalStock} total units',
                  style: TextStyle(
                    color: AppConstants.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: AppConstants.spacing.lg),
                _ProductStatsGrid(provider: provider),
                SizedBox(height: AppConstants.spacing.lg),
                SearchBarWidget(
                  onChanged: provider.search,
                  focusNode: _searchFocusNode,
                  hintText: 'Search by name, SKU, brand...',
                ),
                SizedBox(height: AppConstants.spacing.md),
                if (categories.length > 1) ...<Widget>[
                  _CategoryChipRow(
                    categories: categories,
                    selected: _selectedCategory,
                    onSelected: (String value) =>
                        setState(() => _selectedCategory = value),
                  ),
                  SizedBox(height: AppConstants.spacing.md),
                ],
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
                  ? EmptyInventory(
                      key: ValueKey<String>(
                        '$_selectedCategory-${provider.selectedFilter}-${provider.searchQuery}',
                      ),
                      message: 'No products found.\nTry adjusting your filters.',
                    )
                  : ListView.separated(
                      key: ValueKey<String>(
                        '${_selectedCategory}_list',
                      ),
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

/// Headline stat grid (Total Products, Total Stock, Out of Stock, Low
/// Stock), matching the React Products page's `StatCard` row. Reuses the
/// same [MetricCard] built for the Dashboard screen.
class _ProductStatsGrid extends StatelessWidget {
  const _ProductStatsGrid({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.spacing.md,
      crossAxisSpacing: AppConstants.spacing.md,
      childAspectRatio: 1.7,
      children: <Widget>[
        MetricCard(
          label: 'Total Products',
          value: '${provider.totalItems}',
          accentColor: tokens.chart1,
        ),
        MetricCard(
          label: 'Total Stock',
          value: '${provider.totalStock}',
          accentColor: tokens.chart4,
        ),
        MetricCard(
          label: 'Out of Stock',
          value: '${provider.outOfStockCount}',
          accentColor: tokens.destructive,
        ),
        MetricCard(
          label: 'Low Stock',
          value: '${provider.lowStockCount}',
          accentColor: tokens.chart5,
        ),
      ],
    );
  }
}

/// New: product-category filter chips (React's first filter row). Distinct
/// from the existing [CategoryFilterBar] widget, which — despite its name
/// — filters by stock status ("In Stock" / "Low Stock" / ...), not by
/// product category. Both rows are shown, matching the two independent
/// filter rows on the React Products page.
class _CategoryChipRow extends StatelessWidget {
  const _CategoryChipRow({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: AppConstants.spacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final String category = categories[index];
          final bool isSelected = category == selected;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            backgroundColor: tokens.card,
            selectedColor: tokens.primary,
            side: BorderSide(
              color: isSelected ? tokens.primary : tokens.border,
            ),
            labelStyle: TextStyle(
              color: isSelected ? tokens.primaryForeground : tokens.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radii.pill),
            ),
          );
        },
      ),
    );
  }
}
