import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_routes.dart';
import '../widgets/transaction_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final transactions = provider.transactions.where((tx) {
      final query = _searchQuery.toLowerCase();
      return tx.entityName.toLowerCase().contains(query) ||
          tx.id.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('TRANSACTION HISTORY'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacing.page,
              vertical: AppConstants.spacing.md,
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by ID or name...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radii.md),
                ),
              ),
            ),
          ),
        ),
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 64,
                    color: AppConstants.colors.textMuted.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found.',
                    style: TextStyle(color: AppConstants.colors.textMuted),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppConstants.spacing.page),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return TransactionCard(
                  transaction: tx,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.transactionDetails,
                    arguments: tx,
                  ),
                );
              },
            ),
    );
  }
}
