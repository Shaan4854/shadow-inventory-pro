import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_form_sheet.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customers = provider.searchCustomers(_query);

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('CUSTOMERS'),
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
                hintText: 'Search by name or phone...',
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
          : customers.isEmpty
              ? _EmptyCustomers(onAdd: () => _showForm(context, provider))
              : ListView.builder(
                  padding: EdgeInsets.all(AppConstants.spacing.page),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return CustomerCard(
                      customer: customer,
                      onEdit: () => _showForm(context, provider, customer),
                      onDelete: () => _confirmDelete(context, provider, customer),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, provider),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  void _showForm(BuildContext context, CustomerProvider provider, [dynamic customer]) {
    CustomerFormSheet.show(context, provider: provider, customer: customer);
  }

  Future<void> _confirmDelete(BuildContext context, CustomerProvider provider, dynamic customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
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
      await provider.deleteCustomer(customer.id);
    }
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: AppConstants.colors.textMuted.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No customers yet',
            style: TextStyle(
              color: AppConstants.colors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAdd,
            child: const Text('Add your first customer'),
          ),
        ],
      ),
    );
  }
}
