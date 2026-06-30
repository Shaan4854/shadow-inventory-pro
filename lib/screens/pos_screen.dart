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

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<TransactionItem> _cart = [];
  final TextEditingController _customerController =
      TextEditingController(text: 'Walk-in Customer');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController =
      TextEditingController(text: '0');
  String _paymentMethod = 'Cash';

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _grandTotal => _subtotal - _discount;

  double get _totalProfit {
    final provider = context.read<ProductProvider>();
    return _cart.fold(0.0, (sum, item) {
          final product =
              provider.products.firstWhere((p) => p.id == item.productId);
          return sum + ((item.priceAtTime - product.buyPrice) * item.quantity);
        }) -
        _discount;
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out of stock!')),
      );
      return;
    }

    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        final existing = _cart[existingIndex];
        if (existing.quantity >= product.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insufficient stock!')),
          );
          return;
        }
        _cart[existingIndex] = TransactionItem(
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
        _cart.add(TransactionItem(
          id: const Uuid().v4(),
          transactionId: 'PENDING',
          productId: product.id,
          quantity: 1,
          priceAtTime: product.sellPrice,
          productName: product.name,
          productEmoji: product.emoji,
          productUnit: product.unit,
        ),);
      }
    });
  }

  void _updateQuantity(int index, int quantity) {
    final item = _cart[index];
    final product = context
        .read<ProductProvider>()
        .products
        .firstWhere((p) => p.id == item.productId);

    if (quantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient stock!')),
      );
      return;
    }

    setState(() {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = TransactionItem(
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

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty.')),
      );
      return;
    }

    final String transactionId = const Uuid().v4();
    final transaction = Transaction(
      id: transactionId,
      type: TransactionType.sale,
      totalAmount: _subtotal,
      discount: _discount,
      notes: _notesController.text,
      entityName: _customerController.text,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      items: _cart
          .map((item) => TransactionItem(
                id: item.id,
                transactionId: transactionId,
                productId: item.productId,
                quantity: item.quantity,
                priceAtTime: item.priceAtTime,
              ),)
          .toList(),
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
        title: const Text('POINT OF SALE'),
        actions: [
          IconButton(
            onPressed: () => _showSearch(context),
            icon: const Icon(Icons.search_rounded),
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
                  _CartHeader(
                    itemCount: _cart.length,
                    onClear: () => setState(() => _cart.clear()),
                  ),
                  if (_cart.isEmpty)
                    _EmptyCart(onAdd: () => _showSearch(context))
                  else
                    ..._cart.asMap().entries.map((e) => _CartItemTile(
                          item: e.value,
                          onQuantityChanged: (q) => _updateQuantity(e.key, q),
                        ),),
                  SizedBox(height: AppConstants.spacing.lg),
                  const _SectionHeader(title: 'Transaction Details'),
                  TextField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    items: ['Cash', 'UPI', 'Card', 'Credit']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing.md),
                  TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Discount',
                      prefixText: AppConstants.currencySymbol,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          _ProfitPreview(profit: _totalProfit),
          PaymentSummary(
            subtotal: _subtotal,
            discount: _discount,
            grandTotal: _grandTotal,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.spacing.page,
              0,
              AppConstants.spacing.page,
              AppConstants.spacing.page,
            ),
            color: AppConstants.colors.surface,
            child: FilledButton(
              onPressed: _checkout,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radii.md),),
              ),
              child: const Text('COMPLETE SALE',
                  style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radii.sheet),),
      ),
      builder: (_) => _ProductPicker(onSelected: _addToCart),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.itemCount, required this.onClear});

  final int itemCount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CART ($itemCount)',
            style: TextStyle(
              color: AppConstants.colors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          if (itemCount > 0)
            TextButton(
              onPressed: onClear,
              child: Text('Clear',
                  style: TextStyle(color: AppConstants.colors.red),),
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.shopping_basket_outlined,
              size: 64,
              color: AppConstants.colors.textMuted.withValues(alpha: 0.5),),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: TextStyle(color: AppConstants.colors.textMuted),),
          TextButton(onPressed: onAdd, child: const Text('Browse Products')),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onQuantityChanged});

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
          Text(item.productEmoji, style: const TextStyle(fontSize: 24)),
          SizedBox(width: AppConstants.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),),
                Text(
                  '${AppConstants.currencySymbol}${item.priceAtTime} x ${item.quantity}',
                  style: TextStyle(
                      color: AppConstants.colors.textSecondary, fontSize: 12,),
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

class _ProfitPreview extends StatelessWidget {
  const _ProfitPreview({required this.profit});
  final double profit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppConstants.colors.green.withValues(alpha: 0.05),
      child: Center(
        child: Text(
          'Estimated Profit: ${AppConstants.currencySymbol}${profit.toStringAsFixed(2)}',
          style: TextStyle(
              color: AppConstants.colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing.md),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppConstants.colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
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
          p.sku.toLowerCase().contains(_query.toLowerCase()) ||
          p.barcode.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by name, SKU or barcode...',
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
                final isOutOfStock = p.stock <= 0;
                return ListTile(
                  leading: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(p.name),
                  subtitle: Text(
                      'Stock: ${p.stock} ${p.unit} • ${AppConstants.currencySymbol}${p.sellPrice}',),
                  trailing: isOutOfStock
                      ? const Text('Out of Stock',
                          style: TextStyle(color: Colors.red, fontSize: 10),)
                      : const Icon(Icons.add_shopping_cart_rounded, size: 20),
                  enabled: !isOutOfStock,
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
