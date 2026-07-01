import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/transaction_card.dart';
import '../widgets/commerce_cart_item.dart';
import '../widgets/transaction_summary.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  Transaction? _originalTransaction;
  final List<TransactionItem> _returnItems = [];
  final TextEditingController _reasonController = TextEditingController();

  int get _itemCount => _returnItems.where((i) => i.quantity > 0).length;
  int get _totalQuantity => _returnItems.fold(0, (sum, item) => sum + item.quantity);
  double get _subtotal => _returnItems.fold(0, (sum, item) => sum + item.total);

  void _selectTransaction(Transaction tx) {
    setState(() {
      _originalTransaction = tx;
      _returnItems.clear();
      for (var item in tx.items) {
        _returnItems.add(TransactionItem(
          id: const Uuid().v4(),
          transactionId: 'PENDING',
          productId: item.productId,
          quantity: 0,
          priceAtTime: item.priceAtTime,
          discount: item.discount, // Pro-rated discount logic can be complex, here we use original line discount
          tax: item.tax,
          productName: item.productName,
          productEmoji: item.productEmoji,
          productUnit: item.productUnit,
        ),);
      }
    });
  }

  void _updateReturnQuantity(int index, int quantity) {
    final originalItem = _originalTransaction!.items[index];
    if (quantity > originalItem.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot return more than sold.')),
      );
      return;
    }

    setState(() {
      final item = _returnItems[index];
      _returnItems[index] = TransactionItem(
        id: item.id,
        transactionId: item.transactionId,
        productId: item.productId,
        quantity: quantity,
        priceAtTime: item.priceAtTime,
        discount: (item.priceAtTime > 0) ? (originalItem.discount / originalItem.quantity) * quantity : 0,
        tax: (item.priceAtTime > 0) ? (originalItem.tax / originalItem.quantity) * quantity : 0,
        productName: item.productName,
        productEmoji: item.productEmoji,
        productUnit: item.productUnit,
      );
    });
  }

  Future<void> _processReturn() async {
    final activeItems =
        _returnItems.where((item) => item.quantity > 0).toList();
    if (activeItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one item to return.')),);
      return;
    }

    final String transactionId = const Uuid().v4();
    final returnTx = Transaction(
      id: transactionId,
      type: TransactionType.salesReturn,
      totalAmount: _subtotal,
      discount: 0,
      notes: _reasonController.text,
      entityName: _originalTransaction!.entityName,
      entityId: _originalTransaction!.entityId,
      paidAmount: 0,
      createdAt: DateTime.now(),
      items: activeItems
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

    await context.read<ProductProvider>().addTransaction(returnTx);
    
    if (returnTx.entityId.isNotEmpty) {
      if (mounted) {
        await context.read<CustomerProvider>().updateCustomerBalance(
          returnTx.entityId,
          -returnTx.grandTotal,
        );
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
        title: const Text('SALES RETURN'),
      ),
      body: _originalTransaction == null
          ? _TransactionPicker(
              onSelected: _selectTransaction, type: TransactionType.sale,)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppConstants.spacing.page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Original Sale',
                                style: TextStyle(fontWeight: FontWeight.bold),),
                            TextButton(
                                onPressed: () => setState(() => _originalTransaction = null), 
                                child: const Text('Change'),),
                          ],
                        ),
                        Text('Customer: ${_originalTransaction!.entityName}',
                            style: TextStyle(color: AppConstants.colors.textSecondary),),
                        Text('Date: ${_originalTransaction!.createdAt.toString().split('.')[0]}',
                            style: TextStyle(color: AppConstants.colors.textSecondary),),
                        const Divider(height: 32),
                        const Text('SELECT ITEMS TO RETURN',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,),),
                        SizedBox(height: AppConstants.spacing.md),
                        ..._returnItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final returnItem = entry.value;

                          return CommerceCartItem(
                            item: returnItem,
                            canEditPrice: false,
                            onQuantityChanged: (q) => _updateReturnQuantity(index, q),
                            onRemove: () => _updateReturnQuantity(index, 0),
                          );
                        }),
                        SizedBox(height: AppConstants.spacing.lg),
                        TextField(
                          controller: _reasonController,
                          decoration:
                              const InputDecoration(labelText: 'Reason for return'),
                        ),
                      ],
                    ),
                  ),
                ),
                TransactionSummary(
                  itemCount: _itemCount,
                  totalQuantity: _totalQuantity,
                  subtotal: _subtotal,
                  discount: 0,
                  tax: 0,
                  grandTotal: _subtotal,
                ),
                Container(
                  padding: EdgeInsets.all(AppConstants.spacing.page),
                  color: AppConstants.colors.surface,
                  child: FilledButton(
                    onPressed: _processReturn,
                    style:
                        FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text('CONFIRM RETURN'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TransactionPicker extends StatelessWidget {
  const _TransactionPicker({required this.onSelected, required this.type});
  final ValueChanged<Transaction> onSelected;
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final transactions = context
        .watch<ProductProvider>()
        .transactions
        .where((tx) => tx.type == type)
        .toList();

    if (transactions.isEmpty) {
      return const Center(child: Text('No sales found.'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return TransactionCard(
          transaction: transactions[index],
          onTap: () => onSelected(transactions[index]),
        );
      },
    );
  }
}
