import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/stock_movement.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({this.product, super.key});

  final Product? product;

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  Product? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _adjustmentType = 'Addition';
  String _reasonCategory = 'Manual Correction';

  final List<String> _reasons = ['Damaged', 'Expired', 'Lost', 'Manual Correction', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.product;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _saveAdjustment() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product.')));
      return;
    }

    final int? quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity.')));
      return;
    }

    int change = _adjustmentType == 'Addition' ? quantity : -quantity;

    if (_selectedProduct!.stock + change < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock cannot go below zero.')));
      return;
    }

    final movement = StockMovement(
      id: const Uuid().v4(),
      productId: _selectedProduct!.id,
      type: TransactionType.adjustment,
      quantityChange: change,
      reason: '[$_reasonCategory] ${_reasonController.text}'.trim(),
      createdAt: DateTime.now(),
      productName: _selectedProduct!.name,
      productEmoji: _selectedProduct!.emoji,
    );

    await context.read<ProductProvider>().addStockMovement(movement);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('STOCK ADJUSTMENT'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedProduct == null)
              OutlinedButton.icon(
                onPressed: _showProductPicker,
                icon: const Icon(Icons.search_rounded),
                label: const Text('SELECT PRODUCT'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(_selectedProduct!.emoji, style: const TextStyle(fontSize: 32)),
                title: Text(_selectedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Current Stock: ${_selectedProduct!.stock} ${_selectedProduct!.unit}'),
                trailing: TextButton(onPressed: _showProductPicker, child: const Text('Change')),
              ),
            const Divider(height: 40),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _adjustmentType,
                    items: ['Addition', 'Subtraction']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _adjustmentType = v!),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
                SizedBox(width: AppConstants.spacing.md),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacing.lg),
            DropdownButtonFormField<String>(
              value: _reasonCategory,
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _reasonCategory = v!),
              decoration: const InputDecoration(labelText: 'Reason Category'),
            ),
            SizedBox(height: AppConstants.spacing.lg),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Detailed Reason',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: AppConstants.spacing.xxl),
            FilledButton(
              onPressed: _saveAdjustment,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('SAVE ADJUSTMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radii.sheet)),
      ),
      builder: (_) => _ProductPicker(onSelected: (p) => setState(() => _selectedProduct = p)),
    );
  }
}

class _ProductPicker extends StatefulWidget {
  const _ProductPicker({required this.onSelected});
  final ValueChanged<Product> onSelected;

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products.where((p) {
      return p.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search product...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: AppConstants.spacing.md),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                return ListTile(
                  leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(p.name),
                  subtitle: Text('Current Stock: ${p.stock}'),
                  onTap: () {
                    widget.onSelected(p);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
