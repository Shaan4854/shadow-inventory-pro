import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/customer.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/product_picker.dart';
import '../widgets/commerce_cart_item.dart';
import '../widgets/transaction_summary.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final List<TransactionItem> _cart = [];
  Customer? _selectedCustomer;
  final TextEditingController _customerController =
      TextEditingController(text: 'Walk-in Customer');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _globalDiscountController =
      TextEditingController(text: '0');
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _paidAmountController =
      TextEditingController(text: '0');
  String _paymentMethod = 'Cash';

  int get _itemCount => _cart.length;
  int get _totalQuantity => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get _globalDiscount =>
      double.tryParse(_globalDiscountController.text) ?? 0;
  double get _taxAmount => double.tryParse(_taxController.text) ?? 0;
  double get _grandTotal => _subtotal - _globalDiscount + _taxAmount;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0;

  double get _totalProfit {
    final provider = context.read<ProductProvider>();
    return _cart.fold(0.0, (sum, item) {
          final product =
              provider.products.firstWhere((p) => p.id == item.productId);
          return sum + ((item.priceAtTime - product.buyPrice) * item.quantity) - item.discount;
        }) -
        _globalDiscount;
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
          discount: existing.discount,
          tax: existing.tax,
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
          discount: item.discount,
          tax: item.tax,
          productName: item.productName,
          productEmoji: item.productEmoji,
          productUnit: item.productUnit,
        );
      }
    });
  }

  Future<void> _editItemValue(int index, {required bool isPrice}) async {
    final item = _cart[index];
    final controller = TextEditingController(
      text: (isPrice ? item.priceAtTime : item.discount).toString(),
    );
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPrice ? 'Edit Unit Price' : 'Edit Line Discount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: AppConstants.currencySymbol,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _cart[index] = TransactionItem(
          id: item.id,
          transactionId: item.transactionId,
          productId: item.productId,
          quantity: item.quantity,
          priceAtTime: isPrice ? result : item.priceAtTime,
          discount: isPrice ? item.discount : result,
          tax: item.tax,
          productName: item.productName,
          productEmoji: item.productEmoji,
          productUnit: item.productUnit,
        );
      });
    }
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
      discount: _globalDiscount,
      taxAmount: _taxAmount,
      notes: _notesController.text,
      entityName: _customerController.text,
      entityId: _selectedCustomer?.id ?? '',
      paidAmount: _paymentMethod == 'Credit' ? _paidAmount : _grandTotal,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      items: _cart
          .map((item) => TransactionItem(
                id: item.id,
                transactionId: transactionId,
                productId: item.productId,
                quantity: item.quantity,
                priceAtTime: item.priceAtTime,
                discount: item.discount,
                tax: item.tax,
              ),)
          .toList(),
    );

    await context.read<ProductProvider>().addTransaction(transaction);

    if (_selectedCustomer != null) {
      final double balanceToUpdate = transaction.balanceAmount;
      if (balanceToUpdate != 0) {
        if (mounted) {
          await context
              .read<CustomerProvider>()
              .updateCustomerBalance(_selectedCustomer!.id, balanceToUpdate);
        }
      }
    }

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
            onPressed: () => ProductPicker.show(context, onSelected: _addToCart, showOutOfStock: false),
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'Add Product',
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
                    _EmptyCart(onAdd: () => ProductPicker.show(context, onSelected: _addToCart, showOutOfStock: false))
                  else
                    ..._cart.asMap().entries.map((e) => CommerceCartItem(
                          item: e.value,
                          onQuantityChanged: (q) => _updateQuantity(e.key, q),
                          onRemove: () => setState(() => _cart.removeAt(e.key)),
                          onPriceEdit: () => _editItemValue(e.key, isPrice: true),
                          onDiscountEdit: () => _editItemValue(e.key, isPrice: false),
                        ),),
                  SizedBox(height: AppConstants.spacing.lg),
                  const _SectionHeader(title: 'Transaction Details'),
                  TextField(
                    controller: _customerController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.person_search_rounded),
                        onPressed: () => _showCustomerPicker(context),
                      ),
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
                  if (_paymentMethod == 'Credit') ...[
                    SizedBox(height: AppConstants.spacing.md),
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount Received (Partial Payment)',
                        prefixText: AppConstants.currencySymbol,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  SizedBox(height: AppConstants.spacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _globalDiscountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Global Discount',
                            prefixText: AppConstants.currencySymbol,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: AppConstants.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: _taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tax Amount',
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
                      labelText: 'Transaction Notes',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ProfitPreview(profit: _totalProfit),
          TransactionSummary(
            itemCount: _itemCount,
            totalQuantity: _totalQuantity,
            subtotal: _subtotal,
            discount: _globalDiscount,
            tax: _taxAmount,
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

  void _showCustomerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radii.sheet),),
      ),
      builder: (_) => _CustomerPicker(
        onSelected: (customer) {
          setState(() {
            _selectedCustomer = customer;
            _customerController.text = customer.name;
          });
        },
      ),
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
              child: Text('Clear All',
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
          'Estimated Net Profit: ${AppConstants.currencySymbol}${profit.toStringAsFixed(2)}',
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

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker({required this.onSelected});
  final ValueChanged<Customer> onSelected;

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().searchCustomers(_query);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search customer by name or phone...',
              prefixIcon: Icon(Icons.person_search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: AppConstants.spacing.md),
          Expanded(
            child: customers.isEmpty
                ? const Center(child: Text('No customers found.'))
                : ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.name[0])),
                        title: Text(c.name),
                        subtitle: Text(c.mobile),
                        onTap: () {
                          widget.onSelected(c);
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
