import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
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
    final String? bannerMessage =
        provider.errorMessage ?? provider.alertMessage;
    final AlertBannerType bannerType = provider.errorMessage == null
        ? AlertBannerType.warning
        : AlertBannerType.error;

    _scheduleBannerClear(provider, bannerMessage);

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
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
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppConstants.colors.background,
      selectedItemColor: AppConstants.colors.primary,
      unselectedItemColor: AppConstants.colors.textMuted,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.inventory);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.productList);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.pos);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.purchase);
            break;
          case 4:
            _showMoreMenu(context);
            break;
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), label: 'Products',),
        BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), label: 'Sell'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined), label: 'Purchase',),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people_outline_rounded),
              title: const Text('Customers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.customers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.business_rounded),
              title: const Text('Suppliers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.suppliers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('Inventory Timeline'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.timeline);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('Transaction History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.transactions);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return_outlined),
              title: const Text('Sales Return'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.salesReturn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return_rounded),
              title: const Text('Purchase Return'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.purchaseReturn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Stock Adjustment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.stockAdjustment);
              },
            ),
            SizedBox(height: AppConstants.spacing.md),
          ],
        ),
      ),
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
          SizedBox(height: AppConstants.spacing.lg),
          const _FlowCarousel(),
          SizedBox(height: AppConstants.spacing.md),
          _RecentSuppliersRow(),
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
                    icon: Icon(Icons.sort_rounded,
                        color: AppConstants.colors.primary,),
                    tooltip: 'Sort Products',
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.productList),
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
                child: Text('Sort by',
                    style: Theme.of(context).textTheme.titleMedium,),
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

class _FlowCarousel extends StatelessWidget {
  const _FlowCarousel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Flow',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: AppConstants.spacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FlowItem(
                label: 'Purchase',
                subtitle: 'Add Stock',
                icon: Icons.add_shopping_cart_rounded,
                color: AppConstants.colors.primary,
                onTap: () => Navigator.pushNamed(context, AppRoutes.purchase),
              ),
              _FlowItem(
                label: 'Stock',
                subtitle: 'Adjustment',
                icon: Icons.tune_rounded,
                color: AppConstants.colors.purple,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.stockAdjustment),
              ),
              _FlowItem(
                label: 'Sell',
                subtitle: 'POS System',
                icon: Icons.sell_rounded,
                color: AppConstants.colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.pos),
              ),
              _FlowItem(
                label: 'Return',
                subtitle: 'Any Type',
                icon: Icons.assignment_return_rounded,
                color: AppConstants.colors.orange,
                onTap: () => _showReturnMenu(context),
              ),
              _FlowItem(
                label: 'Reports',
                subtitle: 'Coming Soon',
                icon: Icons.analytics_rounded,
                color: AppConstants.colors.blue,
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReturnMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.keyboard_return_rounded),
              title: const Text('Sales Return (from Customer)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.salesReturn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return_rounded),
              title: const Text('Purchase Return (to Supplier)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.purchaseReturn);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports module coming in Phase 9.')),
    );
  }
}

class _FlowItem extends StatelessWidget {
  const _FlowItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: AppConstants.spacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.colors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radii.lg),
            border: Border.all(color: AppConstants.colors.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppConstants.colors.textMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
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
      trailing: selected
          ? Icon(Icons.check_circle, color: AppConstants.colors.primary)
          : null,
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
    );
  }
}

class _RecentSuppliersRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final suppliers = supplierProvider.recentSuppliers;

    if (suppliers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Suppliers',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.suppliers),
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return Padding(
                padding: EdgeInsets.only(right: AppConstants.spacing.md),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.supplierDetails,
                    arguments: s,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radii.lg),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.colors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radii.lg),
                      border: Border.all(color: AppConstants.colors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          child: Text(s.name[0], style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.name,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
              _SummaryItem(
                  label: 'Total Products', value: '${provider.totalItems}',),
              _SummaryItem(
                  label: 'Total Stock', value: '${provider.totalStock}',),
            ],
          ),
          SizedBox(height: AppConstants.spacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _SummaryItem(
                label: 'Inventory Value',
                value:
                    '${AppConstants.currencySymbol}${provider.totalBuyValue.round()}',
              ),
              _SummaryItem(
                label: 'Today\'s Profit',
                value:
                    '${AppConstants.currencySymbol}${provider.todayProfit.round()}',
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
    final customerProvider = context.watch<CustomerProvider>();
    final supplierProvider = context.watch<SupplierProvider>();

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
            label: 'Customers',
            value: '${customerProvider.customers.length}',
            color: AppConstants.colors.blue,
            icon: Icons.people_outline,
          ),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: _QuickStatCard(
            label: 'Suppliers',
            value: '${supplierProvider.suppliers.length}',
            color: AppConstants.colors.yellow,
            icon: Icons.business_rounded,
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
            style:
                TextStyle(color: AppConstants.colors.textMuted, fontSize: 10),
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
