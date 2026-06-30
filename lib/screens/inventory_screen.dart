import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/alert_banner.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_inventory.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/stat_pill.dart';

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

  @override
  void dispose() {
    _bannerTimer?.cancel();
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
                    _InventoryHeader(provider: provider),
                    Expanded(child: _InventoryBody(provider: provider)),
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
    // TODO: Open add product bottom sheet in Phase 6.
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({required this.provider});

  final ProductProvider provider;

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
          _StatsRow(provider: provider),
          SizedBox(height: AppConstants.spacing.lg),
          SearchBarWidget(onChanged: provider.search),
          SizedBox(height: AppConstants.spacing.lg),
          CategoryFilterBar(
            selectedFilter: provider.selectedFilter,
            onFilterSelected: provider.setFilter,
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
        Text(
          '🌑',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(width: AppConstants.spacing.md),
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: <Color>[
                  AppConstants.colors.gold,
                  AppConstants.colors.goldLight,
                ],
              ).createShader(bounds);
            },
            child: Text(
              AppConstants.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppConstants.colors.onDanger,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        SizedBox(width: AppConstants.spacing.md),
        Text(
          AppConstants.appSubtitle,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppConstants.colors.textMuted,
              ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.provider});

  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: StatPill(
            value: '${provider.totalItems}',
            label: 'Items',
            accentColor: AppConstants.colors.blue,
          ),
        ),
        SizedBox(width: AppConstants.spacing.sm),
        Expanded(
          child: StatPill(
            value: _money(provider.totalBuyValue),
            label: 'Buy Val',
            accentColor: AppConstants.colors.red,
          ),
        ),
        SizedBox(width: AppConstants.spacing.sm),
        Expanded(
          child: StatPill(
            value: _money(provider.totalProfit),
            label: 'Profit',
            accentColor: AppConstants.colors.green,
          ),
        ),
        SizedBox(width: AppConstants.spacing.sm),
        Expanded(
          child: StatPill(
            value: '${provider.outOfStockCount}',
            label: 'Out',
            accentColor: AppConstants.colors.yellow,
          ),
        ),
      ],
    );
  }

  String _money(double value) {
    return '${AppConstants.currencySymbol}${value.round()}';
  }
}

class _InventoryBody extends StatelessWidget {
  const _InventoryBody({required this.provider});

  final ProductProvider provider;

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
                ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.provider,
    super.key,
  });

  final List<Product> products;
  final ProductProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacing.xxl,
        AppConstants.spacing.lg,
        AppConstants.spacing.xxl,
        AppConstants.spacing.bottomListPadding,
      ),
      itemCount: products.length,
      separatorBuilder: (_, __) => SizedBox(height: AppConstants.spacing.md),
      itemBuilder: (BuildContext context, int index) {
        final Product product = products[index];

        return AnimatedContainer(
          duration: AppConstants.durations.fast,
          curve: Curves.easeOut,
          child: ProductCard(
            product: product,
            profit: provider.unitProfit(product),
            isLowStock: provider.isLowStock(product),
            isOutOfStock: provider.isOutOfStock(product),
            onEdit: () => _handleEdit(product),
            onDelete: () => _confirmDelete(context, product),
          ),
        );
      },
    );
  }

  void _handleEdit(Product product) {
    // TODO: Open edit product bottom sheet in Phase 6.
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
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