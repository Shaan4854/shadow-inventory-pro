import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/transaction_card.dart';

class PurchaseReturnScreen extends StatefulWidget {
  const PurchaseReturnScreen({super.key});

  @override
  State<PurchaseReturnScreen> createState() => _PurchaseReturnScreenState();
}

class _PurchaseReturnScreenState extends State<PurchaseReturnScreen> {
  Transaction? _originalTransaction;
  final List<TransactionItem> _returnItems = [];
  final TextEditingController _reasonController = TextEditingController();

  void _selectTransaction(Transaction tx) {
    setState(() {
      _originalTransaction = tx;
      _returnItems.clear();
      // Initialize return items with zero quantity
      for (var item in tx.items) {
        _returnItems.add(TransactionItem(
          id: const Uuid().v4(),
          transactionId: 'PENDING',
          productId: item.productId,
          quantity: 0,
          priceAtTime: item.priceAtTime,
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
        const SnackBar(content: Text('Cannot return more than purchased.')),
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
      type: TransactionType.purchaseReturn,
      totalAmount: activeItems.fold(0, (sum, item) => sum + item.total),
      discount: 0,
      notes: _reasonController.text,
      entityName: _originalTransaction!.entityName,
      createdAt: DateTime.now(),
      items: activeItems
          .map((item) => TransactionItem(
                id: item.id,
                transactionId: transactionId,
                productId: item.productId,
                quantity: item.quantity,
                priceAtTime: item.priceAtTime,
              ),)
          .toList(),
    );

    await context.read<ProductProvider>().addTransaction(returnTx);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('PURCHASE RETURN'),
      ),
      body: _originalTransaction == null
          ? _TransactionPicker(
              onSelected: _selectTransaction, type: TransactionType.purchase,)
          : _ReturnForm(
              original: _originalTransaction!,
              returnItems: _returnItems,
              reasonController: _reasonController,
              onQuantityChanged: _updateReturnQuantity,
              onCancel: () => setState(() => _originalTransaction = null),
              onConfirm: _processReturn,
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
      return const Center(child: Text('No transactions found.'));
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

class _ReturnForm extends StatelessWidget {
  const _ReturnForm({
    required this.original,
    required this.returnItems,
    required this.reasonController,
    required this.onQuantityChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final Transaction original;
  final List<TransactionItem> returnItems;
  final TextEditingController reasonController;
  final void Function(int, int) onQuantityChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    const Text('Original Transaction',
                        style: TextStyle(fontWeight: FontWeight.bold),),
                    TextButton(
                        onPressed: onCancel, child: const Text('Change'),),
                  ],
                ),
                Text('Supplier: ${original.entityName}',
                    style: TextStyle(color: AppConstants.colors.textSecondary),),
                Text('Date: ${original.createdAt.toString().split('.')[0]}',
                    style: TextStyle(color: AppConstants.colors.textSecondary),),
                const Divider(height: 32),
                const Text('SELECT ITEMS TO RETURN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,),),
                SizedBox(height: AppConstants.spacing.md),
                ...original.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final originalItem = entry.value;
                  final returnItem = returnItems[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.colors.surface,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radii.md),
                      border: Border.all(color: AppConstants.colors.border),
                    ),
                    child: Row(
                      children: [
                        Text(originalItem.productEmoji,
                            style: const TextStyle(fontSize: 20),),
                        SizedBox(width: AppConstants.spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(originalItem.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,),),
                              Text('Purchased: ${originalItem.quantity}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.colors.textMuted,),),
                            ],
                          ),
                        ),
                        _QuantitySelector(
                          value: returnItem.quantity,
                          max: originalItem.quantity,
                          onChanged: (q) => onQuantityChanged(index, q),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: AppConstants.spacing.lg),
                TextField(
                  controller: reasonController,
                  decoration:
                      const InputDecoration(labelText: 'Reason for return'),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(AppConstants.spacing.page),
          color: AppConstants.colors.surface,
          child: FilledButton(
            onPressed: onConfirm,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('CONFIRM RETURN'),
          ),
        ),
      ],
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector(
      {required this.value, required this.max, required this.onChanged,});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),),
      ],
    );
  }
}
