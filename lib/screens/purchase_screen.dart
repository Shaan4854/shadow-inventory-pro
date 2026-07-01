import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/supplier.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/product_picker.dart';
import '../widgets/commerce_cart_item.dart';
import '../widgets/transaction_summary.dart';
import '../widgets/supplier_form_sheet.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final List<TransactionItem> _items = [];
  Supplier? _selectedSupplier;
  final TextEditingController _entityController =
      TextEditingController(text: 'Primary Supplier');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _globalDiscountController =
      TextEditingController(text: '0');
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _transportController =
      TextEditingController(text: '0');
  final TextEditingController _paidAmountController =
      TextEditingController(text: '0');
  String _paymentMethod = 'Cash';

  int get _itemCount => _items.length;
  int get _totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _globalDiscount => double.tryParse(_globalDiscountController.text) ?? 0;
  double get _taxAmount => double.tryParse(_taxController.text) ?? 0;
  double get _transport => double.tryParse(_transportController.text) ?? 0;
  double get _grandTotal => _subtotal - _globalDiscount + _taxAmount + _transport;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0;

  @override
  void dispose() {
    _entityController.dispose();
    _notesController.dispose();
    _globalDiscountController.dispose();
    _taxController.dispose();
    _transportController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _addItem(Product product) {
    setState(() {
      final existingIndex =
          _items.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        final existing = _items[existingIndex];
        _items[existingIndex] = TransactionItem(
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
        _items.add(TransactionItem(
          id: const Uuid().v4(),
          transactionId: 'PENDING',
          productId: product.id,
          quantity: 1,
          priceAtTime: product.buyPrice,
          productName: product.name,
          productEmoji: product.emoji,
          productUnit: product.unit,
        ),);
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
    final item = _items[index];
    final controller = TextEditingController(
      text: (isPrice ? item.priceAtTime : item.discount).toString(),
    );
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPrice ? 'Edit Cost Price' : 'Edit Line Discount'),
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
        _items[index] = TransactionItem(
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
      discount: _globalDiscount,
      taxAmount: _taxAmount,
      notes: _notesController.text,
      entityName: _entityController.text,
      entityId: _selectedSupplier?.id ?? '',
      paidAmount: _paymentMethod == 'Credit' ? _paidAmount : _grandTotal,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      items: _items
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

    if (_selectedSupplier != null) {
      final double balanceToUpdate = transaction.balanceAmount;
      if (balanceToUpdate != 0) {
        if (mounted) {
          await context
              .read<SupplierProvider>()
              .updateSupplierBalance(_selectedSupplier!.id, balanceToUpdate);
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
        title: const Text('NEW PURCHASE'),
        actions: [
          IconButton(
            onPressed: () => ProductPicker.show(context, onSelected: _addItem),
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
                  _SectionHeader(
                    title: 'Supplier Details',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedSupplier != null)
                          IconButton(
                            onPressed: () => SupplierFormSheet.show(
                              context,
                              provider: context.read<SupplierProvider>(),
                              supplier: _selectedSupplier,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        TextButton(
                          onPressed: () => _showSupplierPicker(context),
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _entityController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier Name',
                      prefixIcon: Icon(Icons.business_rounded),
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
                        labelText: 'Amount Paid (Partial Payment)',
                        prefixText: AppConstants.currencySymbol,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  SizedBox(height: AppConstants.spacing.lg),
                  _CartHeader(
                    itemCount: _items.length,
                    onClear: () => setState(() => _items.clear()),
                  ),
                  if (_items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No products added yet.'),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) => CommerceCartItem(
                          item: entry.value,
                          onQuantityChanged: (q) => _updateQuantity(entry.key, q),
                          onRemove: () => setState(() => _items.removeAt(entry.key)),
                          onPriceEdit: () => _editItemValue(entry.key, isPrice: true),
                          onDiscountEdit: () => _editItemValue(entry.key, isPrice: false),
                        ),),
                  SizedBox(height: AppConstants.spacing.lg),
                  const _SectionHeader(title: 'Additional info'),
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
                    controller: _transportController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Transport / Shipping Cost',
                      prefixText: AppConstants.currencySymbol,
                    ),
                    onChanged: (_) => setState(() {}),
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
          TransactionSummary(
            itemCount: _itemCount,
            totalQuantity: _totalQuantity,
            subtotal: _subtotal + _transport,
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
              onPressed: _savePurchase,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radii.md),),
              ),
              child: const Text('SAVE PURCHASE',
                  style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupplierPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (_) => _SupplierPicker(
        onSelected: (supplier) {
          setState(() {
            _selectedSupplier = supplier;
            _entityController.text = supplier.name;
          });
        },
      ),
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
            'PURCHASE ITEMS ($itemCount)',
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

class _SupplierPicker extends StatefulWidget {
  const _SupplierPicker({required this.onSelected});
  final ValueChanged<Supplier> onSelected;

  @override
  State<_SupplierPicker> createState() => _SupplierPickerState();
}

class _SupplierPickerState extends State<_SupplierPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final suppliers = provider.searchSuppliers(_query);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(AppConstants.spacing.page),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search supplier...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(width: AppConstants.spacing.md),
              IconButton.filled(
                onPressed: () => SupplierFormSheet.show(context, provider: provider),
                icon: const Icon(Icons.add_business_rounded),
                tooltip: 'Add New Supplier',
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing.md),
          Expanded(
            child: suppliers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No suppliers found.'),
                        TextButton(
                          onPressed: () =>
                              SupplierFormSheet.show(context, provider: provider),
                          child: const Text('Add your first supplier'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final s = suppliers[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(s.name[0])),
                        title: Text(s.name),
                        subtitle: Text(s.mobile),
                        onTap: () {
                          widget.onSelected(s);
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
