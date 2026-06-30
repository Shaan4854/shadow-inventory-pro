import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/payment_summary.dart';
import '../widgets/quantity_stepper.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final List<TransactionItem> _items = [];
  final TextEditingController _entityController = TextEditingController(text: 'Primary Supplier');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _transportController = TextEditingController(text: '0');

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _transport => double.tryParse(_transportController.text) ?? 0;
  double get _grandTotal => _subtotal - _discount + _transport;

  @override
  void dispose() {
    _entityController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _transportController.dispose();
    super.dispose();
  }

  void _addItem(Product product) {
    setState(() {
      final existingIndex = _items.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        final existing = _items[existingIndex];
        _items[existingIndex] = TransactionItem(
          id: existing.id,
          transactionId: existing.transactionId,
          productId: existing.productId,
          quantity: existing.quantity + 1,
          priceAtTime: existing.priceAtTime,
          productName: existing.productName,
          productEmoji: existing.productEmoji,
          productUnit: existing.productUnit,
        );
      } else {
        _items.add(TransactionItem(
          id: const Uuid().v4(),
          transactionId: 'PENDING',
          productId: product.id,
          quantity: 1,
          priceAtTime: product.buyPrice,
          productName: product.name,
          productEmoji: product.emoji,
          productUnit: product.unit,
        ));
      }
    });
  }

  void _updateQuantity(int index, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        final item = _items[index];
        _items[index] = TransactionItem(
          id: item.id,
          transactionId: item.transactionId,
          productId: item.productId,
          quantity: quantity,
          priceAtTime: item.priceAtTime,
          productName: item.productName,
          productEmoji: item.productEmoji,
          productUnit: item.productUnit,
        );
      }
    });
  }

  Future<void> _savePurchase() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product.')),
      );
      return;
    }

    final String transactionId = const Uuid().v4();
    final transaction = Transaction(
      id: transactionId,
      type: TransactionType.purchase,
      totalAmount: _subtotal + _transport,
      discount: _discount,
      notes: _notesController.text,
      entityName: _entityController.text,
      createdAt: DateTime.now(),
      items: _items.map((item) => TransactionItem(
        id: item.id,
        transactionId: transactionId,
        productId: item.productId,
        quantity: item.quantity,
        priceAtTime: item.priceAtTime,
      )).toList(),
    );

    await context.read<ProductProvider>().addTransaction(transaction);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('NEW PURCHASE'),
        actions: [
          IconButton(
            onPressed: _savePurchase,
            icon: const Icon(Icons.check_rounded),
            color: AppConstants.colors.green,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.spacing.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    title: 'Supplier Details',
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Change'),
                    ),
                  ),
                  TextField(
                    controller: _entityController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing.lg),
                  _SectionHeader(
                    title: 'Products',
                    trailing: IconButton(
                      onPressed: () => _showProductPicker(context),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: AppConstants.colors.primary,
                    ),
                  ),
                  if (_items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No products added yet.'),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) => _PurchaseItemTile(
                          item: entry.value,
                          onQuantityChanged: (q) => _updateQuantity(entry.key, q),
                        )),
                  SizedBox(height: AppConstants.spacing.lg),
                  _SectionHeader(title: 'Additional info'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Discount',
                            prefixText: AppConstants.currencySymbol,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: _transportController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Transport',
                            prefixText: AppConstants.currencySymbol,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing.md),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Purchase Notes (Internal)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PaymentSummary(
            subtotal: _subtotal + _transport,
            discount: _discount,
            grandTotal: _grandTotal,
          ),
        ],
      ),
    );
  }

  void _showProductPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radii.sheet)),
      ),
      builder: (_) => _ProductPicker(onSelected: _addItem),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppConstants.colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PurchaseItemTile extends StatelessWidget {
  const _PurchaseItemTile({required this.item, required this.onQuantityChanged});

  final TransactionItem item;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing.md),
      padding: EdgeInsets.all(AppConstants.spacing.md),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.colors.background,
              borderRadius: BorderRadius.circular(AppConstants.radii.md),
            ),
            alignment: Alignment.center,
            child: Text(item.productEmoji, style: const TextStyle(fontSize: 20)),
          ),
          SizedBox(width: AppConstants.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${AppConstants.currencySymbol}${item.priceAtTime} / ${item.productUnit}',
                  style: TextStyle(color: AppConstants.colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          QuantityStepper(
            value: item.quantity,
            onChanged: onQuantityChanged,
          ),
        ],
      ),
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
      return p.name.toLowerCase().contains(_query.toLowerCase()) ||
             p.sku.toLowerCase().contains(_query.toLowerCase());
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
                  subtitle: Text('${AppConstants.currencySymbol}${p.buyPrice}'),
                  trailing: const Icon(Icons.add_circle_outline_rounded),
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
