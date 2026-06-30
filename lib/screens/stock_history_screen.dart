import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/timeline_tile.dart';

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final movements =
        provider.movements.where((m) => m.productId == product.id).toList();

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STOCK HISTORY', style: TextStyle(fontSize: 16)),
            Text(product.name,
                style: TextStyle(
                    fontSize: 12, color: AppConstants.colors.textSecondary,),),
          ],
        ),
      ),
      body: Column(
        children: [
          _StockHeader(product: product),
          Expanded(
            child: movements.isEmpty
                ? const Center(child: Text('No history for this product.'))
                : ListView.builder(
                    padding: EdgeInsets.all(AppConstants.spacing.page),
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      return TimelineTile(movement: movements[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockHeader extends StatelessWidget {
  const _StockHeader({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing.page),
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        border: Border(bottom: BorderSide(color: AppConstants.colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Current Stock', value: '${product.stock}'),
          _Stat(label: 'Threshold', value: '${product.alertThreshold}'),
          _Stat(
            label: 'Status',
            value: product.stock <= product.alertThreshold ? 'Low' : 'Healthy',
            color: product.stock <= product.alertThreshold
                ? AppConstants.colors.red
                : AppConstants.colors.green,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style:
                TextStyle(color: AppConstants.colors.textMuted, fontSize: 10),),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppConstants.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
