import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';

/// A modal sheet to allow continuous product selection for transactions.
class ProductPicker extends StatefulWidget {
  const ProductPicker({
    required this.onSelected,
    this.showOutOfStock = true,
    this.title = 'Add Products',
    super.key,
  });

  final ValueChanged<Product> onSelected;
  final bool showOutOfStock;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<Product> onSelected,
    bool showOutOfStock = true,
    String title = 'Add Products',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (_) => ProductPicker(
        onSelected: onSelected,
        showOutOfStock: showOutOfStock,
        title: title,
      ),
    );
  }

  @override
  State<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<ProductPicker> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.products.where((p) {
      final matchesQuery =
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
              p.sku.toLowerCase().contains(_query.toLowerCase()) ||
              p.barcode.toLowerCase().contains(_query.toLowerCase());
      if (!widget.showOutOfStock && p.stock <= 0) return false;
      return matchesQuery;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.colors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('DONE'),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing.md),
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search by name, SKU or barcode...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (v) {
              if (products.length == 1) {
                _handleSelection(products.first);
              }
            },
          ),
          SizedBox(height: AppConstants.spacing.md),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(color: AppConstants.colors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final isOutOfStock = p.stock <= 0;
                      return ListTile(
                        leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Stock: ${p.stock} ${p.unit} • ${AppConstants.currencySymbol}${p.sellPrice}',
                        ),
                        trailing: isOutOfStock
                            ? const Text(
                                'Out of Stock',
                                style: TextStyle(color: Colors.red, fontSize: 10),
                              )
                            : Icon(
                                Icons.add_circle_outline_rounded,
                                color: AppConstants.colors.primary,
                              ),
                        enabled: !isOutOfStock || widget.showOutOfStock,
                        onTap: () => _handleSelection(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSelection(Product product) {
    widget.onSelected(product);
    
    // Visual feedback that item was added
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8,
          left: 20,
          right: 20,
        ),
      ),
    );
  }
}
