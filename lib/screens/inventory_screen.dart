import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../utils/sort_type.dart';
import '../widgets/alert_banner.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_inventory.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/search_bar_widget.dart';

/// Main inventory dashboard assembled from reusable Shadow widgets.
class InventoryScreen extends StatefulWidget {
  /// Creates the inventory screen.
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  Timer? _bannerTimer;
  String? _lastBannerMessage;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProductProvider provider = context.watch<ProductProvider>();
    final String? bannerMessage = provider.errorMessage ?? provider.alertMessage;
    final AlertBannerType bannerType = provider.errorMessage == null
        ? AlertBannerType.warning
        : AlertBannerType.error;

    _scheduleBannerClear(provider, bannerMessage);

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      bottomNavigationBar: _BottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddPressed,
        tooltip: 'Add item',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: Column(
                  children: <Widget>[
                    const Focus(autofocus: true, child: SizedBox.shrink()),
                    _InventoryHeader(
                      provider: provider,
                      searchFocusNode: _searchFocusNode,
                    ),
                    Expanded(
                      child: _InventoryBody(
                        provider: provider,
                        searchFocusNode: _searchFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AlertBanner(
            message: bannerMessage,
            isVisible: bannerMessage != null,
            type: bannerType,
          ),
        ],
      ),
    );
  }

  void _scheduleBannerClear(
    ProductProvider provider,
    String? bannerMessage,
  ) {
    if (bannerMessage == null || bannerMessage == _lastBannerMessage) {
      return;
    }

    _lastBannerMessage = bannerMessage;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(AppConstants.durations.alertVisible, () {
      if (!mounted) {
        return;
      }

      provider
        ..clearAlert()
        ..clearError();
      _lastBannerMessage = null;
    });
  }

  void _handleAddPressed() {
    _searchFocusNode.unfocus();
    ProductFormSheet.show(context, provider: context.read<ProductProvider>());
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppConstants.colors.background,
      selectedItemColor: AppConstants.colors.primary,
      unselectedItemColor: AppConstants.colors.textMuted,
      currentIndex: 0,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), label: 'Sell'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Purchase'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.provider,
    required this.searchFocusNode,
  });

  final ProductProvider provider;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.durations.normal,
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacing.page,
        AppConstants.spacing.xs,
        AppConstants.spacing.page,
        AppConstants.spacing.md,
      ),
      color: AppConstants.colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _TitleRow(),
          SizedBox(height: AppConstants.spacing.lg),
          _SummaryCard(provider: provider),
          SizedBox(height: AppConstants.spacing.lg),
          _QuickStatsGrid(provider: provider),
          SizedBox(height: AppConstants.spacing.lg),
          SearchBarWidget(
            onChanged: provider.search,
            focusNode: searchFocusNode,
          ),
          SizedBox(height: AppConstants.spacing.lg),
          CategoryFilterBar(
            selectedFilter: provider.selectedFilter,
            onFilterSelected: provider.setFilter,
          ),
          SizedBox(height: AppConstants.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Recent Products',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => _showSortSheet(context, provider),
                    icon: Icon(Icons.sort_rounded, color: AppConstants.colors.primary),
                    tooltip: 'Sort Products',
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: TextStyle(color: AppConstants.colors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context, ProductProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(AppConstants.spacing.page),
                child: Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
              ),
              _SortTile(
                label: 'Newest First',
                type: SortType.newest,
                selected: provider.selectedSort == SortType.newest,
                onTap: () => provider.setSort(SortType.newest),
              ),
              _SortTile(
                label: 'Name (A-Z)',
                type: SortType.nameAsc,
                selected: provider.selectedSort == SortType.nameAsc,
                onTap: () => provider.setSort(SortType.nameAsc),
              ),
              _SortTile(
                label: 'Stock (Low to High)',
                type: SortType.stockAsc,
                selected: provider.selectedSort == SortType.stockAsc,
                onTap: () => provider.setSort(SortType.stockAsc),
              ),
              _SortTile(
                label: 'Price (High to Low)',
                type: SortType.priceDesc,
                selected: provider.selectedSort == SortType.priceDesc,
                onTap: () => provider.setSort(SortType.priceDesc),
              ),
              SizedBox(height: AppConstants.spacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final SortType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? Icon(Icons.check_circle, color: AppConstants.colors.primary) : null,
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        gradient: AppConstants.colors.dashboardGradient,
        borderRadius: BorderRadius.circular(AppConstants.radii.xl),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _SummaryItem(label: 'Total Products', value: '${provider.totalItems}'),
              _SummaryItem(label: 'Total Stock', value: '${provider.totalItems * 20}'), // Mock multiplier
            ],
          ),
          SizedBox(height: AppConstants.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _SummaryItem(
                label: 'Inventory Value',
                value: '${AppConstants.currencySymbol}${provider.totalBuyValue.round()}',
              ),
              _SummaryItem(
                label: 'Today\'s Profit',
                value: '${AppConstants.currencySymbol}${provider.totalProfit.round()}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickStatCard(
            label: 'Low Stock',
            value: '${provider.lowStockCount}',
            color: AppConstants.colors.red,
            icon: Icons.warning_amber_rounded,
          ),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: _QuickStatCard(
            label: 'Out of Stock',
            value: '${provider.outOfStockCount}',
            color: AppConstants.colors.orange,
            icon: Icons.error_outline_rounded,
          ),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: _QuickStatCard(
            label: 'Categories',
            value: '${provider.categories.length}',
            color: AppConstants.colors.blue,
            icon: Icons.category_outlined,
          ),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: _QuickStatCard(
            label: 'Suppliers',
            value: '15',
            color: AppConstants.colors.yellow,
            icon: Icons.people_outline,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.md),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          SizedBox(height: AppConstants.spacing.xs),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppConstants.colors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: AppConstants.colors.surface,
          radius: 18,
          child: const Text('👤', style: TextStyle(fontSize: 18)),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Good Morning, Shadow! 👋',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.colors.textMuted,
                    ),
              ),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({
    required this.provider,
    required this.searchFocusNode,
  });

  final ProductProvider provider;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    final List<Product> products = provider.filteredProducts;

    return AnimatedSwitcher(
      duration: AppConstants.durations.normal,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const EmptyInventory()
              : _ProductList(
                  key: ValueKey<String>(
                    '${provider.selectedFilter}-${provider.searchQuery}',
                  ),
                  products: products,
                  provider: provider,
                  searchFocusNode: searchFocusNode,
                ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.provider,
    required this.searchFocusNode,
    super.key,
  });

  final List<Product> products;
  final ProductProvider provider;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacing.page,
        AppConstants.spacing.md,
        AppConstants.spacing.page,
        AppConstants.spacing.bottomListPadding,
      ),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];

        return ProductCard(
          product: product,
          profit: provider.unitProfit(product),
          isLowStock: provider.isLowStock(product),
          isOutOfStock: provider.isOutOfStock(product),
          onEdit: () => _handleDetails(context, product),
          onDelete: () => _confirmDelete(context, product),
        );
      },
    );
  }

  void _handleDetails(BuildContext context, Product product) {
    searchFocusNode.unfocus();
    Navigator.of(context).pushNamed(
      AppRoutes.productDetails,
      arguments: product,
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    searchFocusNode.unfocus();
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