import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/supplier_card.dart';
import '../widgets/supplier_form_sheet.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final suppliers = provider.searchSuppliers(_query);

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('SUPPLIERS'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacing.page,
              vertical: AppConstants.spacing.md,
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name, contact or phone...',
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
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? _EmptySuppliers(onAdd: () => _showForm(context, provider))
              : ListView.builder(
                  padding: EdgeInsets.all(AppConstants.spacing.page),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return SupplierCard(
                      supplier: supplier,
                      onEdit: () => _showForm(context, provider, supplier),
                      onDelete: () => _confirmDelete(context, provider, supplier),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, provider),
        child: const Icon(Icons.add_business_rounded),
      ),
    );
  }

  void _showForm(BuildContext context, SupplierProvider provider, [dynamic supplier]) {
    SupplierFormSheet.show(context, provider: provider, supplier: supplier);
  }

  Future<void> _confirmDelete(BuildContext context, SupplierProvider provider, dynamic supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteSupplier(supplier.id);
    }
  }
}

class _EmptySuppliers extends StatelessWidget {
  const _EmptySuppliers({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_center_outlined,
            size: 80,
            color: AppConstants.colors.textMuted.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No suppliers yet',
            style: TextStyle(
              color: AppConstants.colors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('Add your first supplier'),
          ),
        ],
      ),
    );
  }
}
