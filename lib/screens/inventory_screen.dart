import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/supplier_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../utils/sort_type.dart';
import '../widgets/action_button.dart';
import '../widgets/alert_banner.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_inventory.dart';
import '../widgets/metric_card.dart';
import '../widgets/product_card.dart';
import '../widgets/product_form_sheet.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/section_header.dart';
import '../widgets/stock_alert_chip.dart';
import '../widgets/transaction_card.dart';

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
              leading: const Icon(Icons.analytics_rounded),
              title: const Text('Reports & Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.reports);
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
          _StockAlerts(provider: provider),
          _MetricsGrid(provider: provider),
          SizedBox(height: AppConstants.spacing.md),
          _QuickMetricsGrid(provider: provider),
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
            children: <Widget>[
              Expanded(
                child: SectionHeader(
                  title: 'Recent Products',
                  actionLabel: 'View All',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.productList),
                ),
              ),
              IconButton(
                onPressed: () => _showSortSheet(context, provider),
                icon: Icon(
                  Icons.sort_rounded,
                  color: AppConstants.colors.primary,
                ),
                tooltip: 'Sort Products',
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
                child: Text(
                  'Sort by',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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

/// Inline out-of-stock / low-stock alert chips, matching the React
/// Dashboard's alert pills. Hidden entirely when there is nothing to flag.
class _StockAlerts extends StatelessWidget {
  const _StockAlerts({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final int outOfStock = provider.outOfStockCount;
    final int lowStock = provider.lowStockCount;

    if (outOfStock == 0 && lowStock == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing.lg),
      child: Wrap(
        spacing: AppConstants.spacing.md,
        runSpacing: AppConstants.spacing.md,
        children: <Widget>[
          if (outOfStock > 0)
            StockAlertChip(
              message:
                  '$outOfStock product${outOfStock == 1 ? '' : 's'} out of stock',
              icon: Icons.trending_down_rounded,
              color: tokens.destructive,
            ),
          if (lowStock > 0)
            StockAlertChip(
              message:
                  '$lowStock product${lowStock == 1 ? '' : 's'} running low',
              icon: Icons.warning_amber_rounded,
              color: tokens.chart5,
            ),
        ],
      ),
    );
  }
}

/// Headline stat grid (Total Products, Total Stock, Inventory Value,
/// Today's Profit), reflowed to a 2-col mobile grid. Mirrors the React
/// Dashboard's `StatCard` row. Uses `todayProfit` (existing
/// `ProductProvider` metric) rather than React's "Today's Revenue" — no
/// revenue getter exists on the provider, and adding one would mean
/// writing new business logic, which is out of scope for a UI migration.
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.provider});

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
      childAspectRatio: 1.5,
      children: <Widget>[
        MetricCard(
          label: 'Total Products',
          value: '${provider.totalItems}',
          accentColor: tokens.chart1,
        ),
        MetricCard(
          label: 'Total Stock',
          value: '${provider.totalStock}',
          sub: 'units in inventory',
          accentColor: tokens.chart4,
        ),
        MetricCard(
          label: 'Inventory Value',
          value:
              '${AppConstants.currencySymbol}${provider.totalBuyValue.round()}',
          accentColor: tokens.chart3,
        ),
        MetricCard(
          label: "Today's Profit",
          value:
              '${AppConstants.currencySymbol}${provider.todayProfit.round()}',
          accentColor: tokens.chart5,
        ),
      ],
    );
  }
}

/// Compact icon-led quick metrics (Out of Stock, Low Stock, Customers,
/// Suppliers), matching the React Dashboard's "Quick Metrics" row.
class _QuickMetricsGrid extends StatelessWidget {
  const _QuickMetricsGrid({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    final ShadowTokens tokens = ShadowTokens.of(context);
    final CustomerProvider customerProvider = context.watch<CustomerProvider>();
    final SupplierProvider supplierProvider = context.watch<SupplierProvider>();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.spacing.md,
      crossAxisSpacing: AppConstants.spacing.md,
      childAspectRatio: 1.7,
      children: <Widget>[
        QuickMetricCard(
          label: 'Out of Stock',
          value: '${provider.outOfStockCount}',
          icon: Icons.trending_down_rounded,
          color: tokens.destructive,
        ),
        QuickMetricCard(
          label: 'Low Stock',
          value: '${provider.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          color: tokens.chart5,
        ),
        QuickMetricCard(
          label: 'Customers',
          value: '${customerProvider.customers.length}',
          icon: Icons.people_outline_rounded,
          color: tokens.primary,
        ),
        QuickMetricCard(
          label: 'Suppliers',
          value: '${supplierProvider.suppliers.length}',
          icon: Icons.business_rounded,
          color: tokens.accent,
        ),
      ],
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
      itemCount: products.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 1),
      itemBuilder: (BuildContext context, int index) {
        if (index == products.length) {
          return Padding(
            padding: EdgeInsets.only(top: AppConstants.spacing.lg),
            child: _DashboardFooter(provider: provider),
          );
        }

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

/// Trailing Dashboard content shown below the product list: Recent
/// Transactions preview + Quick Actions row, matching the React
/// Dashboard's lower sections. Placed after the product browser (rather
/// than before it) so the existing searchable/filterable list — which
/// doubles as this screen's "Recent Products" section — keeps its
/// current scroll position and behavior unchanged.
class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    final List<Transaction> recentTransactions =
        provider.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'Recent Transactions',
          actionLabel: 'View All',
          onAction: () => Navigator.pushNamed(context, AppRoutes.transactions),
        ),
        SizedBox(height: AppConstants.spacing.md),
        if (recentTransactions.isEmpty)
          const _EmptySectionCard(message: 'No transactions yet')
        else
          ...recentTransactions.map(
            (Transaction tx) => TransactionCard(
              transaction: tx,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.transactionDetails,
                arguments: tx,
              ),
            ),
          ),
        SizedBox(height: AppConstants.spacing.lg),
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: AppConstants.spacing.md),
        Wrap(
          spacing: AppConstants.spacing.md,
          runSpacing: AppConstants.spacing.md,
          children: <Widget>[
            ActionButton(
              label: 'New Sale',
              icon: Icons.point_of_sale_rounded,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.pos),
            ),
            ActionButton(
              label: 'New Purchase',
              icon: Icons.local_shipping_outlined,
              variant: ActionButtonVariant.secondary,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.purchase),
            ),
            ActionButton(
              label: 'Add Product',
              icon: Icons.inventory_2_outlined,
              variant: ActionButtonVariant.outline,
              onPressed: () =>
                  ProductFormSheet.show(context, provider: provider),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.spacing.page * 2),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: AppConstants.colors.textMuted),
      ),
    );
  }
}
