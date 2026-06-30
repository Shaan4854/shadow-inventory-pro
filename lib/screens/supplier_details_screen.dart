import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/supplier.dart';
import '../models/transaction_type.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/transaction_card.dart';
import '../widgets/supplier_form_sheet.dart';

class SupplierDetailsScreen extends StatelessWidget {
  const SupplierDetailsScreen({required this.supplier, super.key});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final transactions =
        context.watch<ProductProvider>().transactions.where((tx) {
      return tx.entityId == supplier.id ||
          (tx.entityId.isEmpty && tx.entityName == supplier.name);
    }).toList();

    final purchases = transactions
        .where((tx) => tx.type == TransactionType.purchase)
        .toList();
    final returns = transactions
        .where((tx) => tx.type == TransactionType.purchaseReturn)
        .toList();

    final totalPurchaseValue =
        purchases.fold<double>(0, (sum, tx) => sum + tx.grandTotal);
    final lastPurchaseDate =
        purchases.isEmpty ? null : purchases.first.createdAt;

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('SUPPLIER DETAILS'),
        actions: [
          IconButton(
            onPressed: () => SupplierFormSheet.show(
              context,
              provider: context.read<SupplierProvider>(),
              supplier: supplier,
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SupplierInfoCard(supplier: supplier),
            SizedBox(height: AppConstants.spacing.lg),
            _SupplierStatsGrid(
              totalValue: totalPurchaseValue,
              purchaseCount: purchases.length,
              returnCount: returns.length,
              lastPurchase: lastPurchaseDate,
            ),
            SizedBox(height: AppConstants.spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT TRANSACTIONS',
                  style: TextStyle(
                    color: AppConstants.colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (transactions.isNotEmpty)
                  Text(
                    '${transactions.length} Total',
                    style: TextStyle(
                        color: AppConstants.colors.textMuted, fontSize: 12,),
                  ),
              ],
            ),
            SizedBox(height: AppConstants.spacing.md),
            if (transactions.isEmpty)
              _EmptyHistory()
            else
              ...transactions.take(10).map((tx) => TransactionCard(
                    transaction: tx,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/transaction-details',
                      arguments: tx,
                    ),
                  ),),
          ],
        ),
      ),
    );
  }
}

class _SupplierInfoCard extends StatelessWidget {
  const _SupplierInfoCard({required this.supplier});
  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.lg),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.xl),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppConstants.colors.blue.withValues(alpha: 0.1),
            child: Text(
              supplier.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.colors.blue,
              ),
            ),
          ),
          SizedBox(height: AppConstants.spacing.md),
          Text(
            supplier.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (supplier.contactPerson.isNotEmpty)
            Text(
              supplier.contactPerson,
              style: TextStyle(color: AppConstants.colors.textSecondary),
            ),
          SizedBox(height: AppConstants.spacing.lg),
          const Divider(),
          SizedBox(height: AppConstants.spacing.md),
          _InfoRow(icon: Icons.phone_android_outlined, label: supplier.mobile),
          if (supplier.email.isNotEmpty)
            _InfoRow(icon: Icons.email_outlined, label: supplier.email),
          if (supplier.address.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, label: supplier.address),
          if (supplier.gstVat.isNotEmpty)
            _InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'GST: ${supplier.gstVat}',),
          SizedBox(height: AppConstants.spacing.lg),
          Container(
            padding: EdgeInsets.all(AppConstants.spacing.md),
            decoration: BoxDecoration(
              color: supplier.outstandingBalance > 0
                  ? AppConstants.colors.orange.withValues(alpha: 0.05)
                  : AppConstants.colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppConstants.radii.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Outstanding Balance',
                    style: TextStyle(fontWeight: FontWeight.w500),),
                Text(
                  '${AppConstants.currencySymbol}${supplier.outstandingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: supplier.outstandingBalance > 0
                        ? AppConstants.colors.orange
                        : AppConstants.colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppConstants.colors.textMuted),
          SizedBox(width: AppConstants.spacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierStatsGrid extends StatelessWidget {
  const _SupplierStatsGrid({
    required this.totalValue,
    required this.purchaseCount,
    required this.returnCount,
    this.lastPurchase,
  });

  final double totalValue;
  final int purchaseCount;
  final int returnCount;
  final DateTime? lastPurchase;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppConstants.spacing.md,
      crossAxisSpacing: AppConstants.spacing.md,
      childAspectRatio: 2.5,
      children: [
        _StatItem(
          label: 'Total Purchases',
          value:
              '${AppConstants.currencySymbol}${totalValue.toStringAsFixed(0)}',
          color: AppConstants.colors.primary,
        ),
        _StatItem(
          label: 'Last Purchase',
          value: lastPurchase != null
              ? DateFormat('MMM dd, yyyy').format(lastPurchase!)
              : 'N/A',
          color: AppConstants.colors.blue,
        ),
        _StatItem(
          label: 'Total Orders',
          value: '$purchaseCount',
          color: AppConstants.colors.green,
        ),
        _StatItem(
          label: 'Returns',
          value: '$returnCount',
          color: AppConstants.colors.red,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.label, required this.value, required this.color,});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.md),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
        border: Border.all(color: AppConstants.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppConstants.colors.textMuted, fontSize: 10,),),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 48,
                color: AppConstants.colors.textMuted.withValues(alpha: 0.2),),
            const SizedBox(height: 16),
            Text('No transactions yet.',
                style: TextStyle(color: AppConstants.colors.textMuted),),
          ],
        ),
      ),
    );
  }
}
