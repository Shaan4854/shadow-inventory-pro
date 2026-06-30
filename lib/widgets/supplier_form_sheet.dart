import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import '../utils/app_constants.dart';

class SupplierFormSheet extends StatefulWidget {
  const SupplierFormSheet({this.supplier, required this.provider, super.key});

  final Supplier? supplier;
  final SupplierProvider provider;

  static Future<void> show(
    BuildContext context, {
    Supplier? supplier,
    required SupplierProvider provider,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (context) => SupplierFormSheet(
        supplier: supplier,
        provider: provider,
      ),
    );
  }

  @override
  State<SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name);
    _contactPersonController =
        TextEditingController(text: widget.supplier?.contactPerson);
    _mobileController = TextEditingController(text: widget.supplier?.mobile);
    _emailController = TextEditingController(text: widget.supplier?.email);
    _addressController = TextEditingController(text: widget.supplier?.address);
    _notesController = TextEditingController(text: widget.supplier?.notes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final supplier = Supplier(
      id: widget.supplier?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      outstandingBalance: widget.supplier?.outstandingBalance ?? 0.0,
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.supplier == null) {
      await widget.provider.addSupplier(supplier);
    } else {
      await widget.provider.updateSupplier(supplier);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spacing.page,
        AppConstants.spacing.page,
        AppConstants.spacing.page,
        MediaQuery.of(context).viewInsets.bottom + AppConstants.spacing.page,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.supplier == null ? 'ADD SUPPLIER' : 'EDIT SUPPLIER',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Company/Supplier Name *',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Supplier name is required' : null,
              ),
              SizedBox(height: AppConstants.spacing.md),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: AppConstants.spacing.md),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Mobile is required' : null,
              ),
              SizedBox(height: AppConstants.spacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppConstants.spacing.md),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                maxLines: 2,
              ),
              SizedBox(height: AppConstants.spacing.md),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Internal Notes',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),
              SizedBox(height: AppConstants.spacing.xl),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'SAVE SUPPLIER',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
