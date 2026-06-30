import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../utils/app_constants.dart';

/// Modal bottom sheet for adding or editing a product.
class ProductFormSheet extends StatefulWidget {
  /// Creates a product form sheet.
  const ProductFormSheet({
    required this.provider,
    this.product,
    super.key,
  });

  /// Opens the add/edit product sheet.
  static Future<void> show(
    BuildContext context, {
    required ProductProvider provider,
    Product? product,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppConstants.colors.backgroundAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radii.sheet),
        ),
      ),
      builder: (_) {
        return ProductFormSheet(
          provider: provider,
          product: product,
        );
      },
    );
  }

  /// Product provider used for persistence through the app state layer.
  final ProductProvider provider;

  /// Product to edit. Null means add mode.
  final Product? product;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  static const Uuid _uuid = Uuid();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _buyController = TextEditingController();
  final TextEditingController _sellController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _alertController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _imagePath;
  String _category = AppConstants.productCategories.first;
  double _profitPreview = 0;
  bool _isSaving = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _buyController.addListener(_updateProfitPreview);
    _sellController.addListener(_updateProfitPreview);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buyController.dispose();
    _sellController.dispose();
    _stockController.dispose();
    _alertController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: AppConstants.durations.normal,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _SheetHandle(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppConstants.spacing.page,
                AppConstants.spacing.xl,
                AppConstants.spacing.page,
                AppConstants.spacing.md,
              ),
              child: Text(
                _isEditMode ? 'Edit Item' : 'Add Item',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConstants.colors.gold,
                    ),
              ),
            ),
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.spacing.page,
                    0,
                    AppConstants.spacing.page,
                    AppConstants.spacing.page,
                  ),
                  children: <Widget>[
                    _ImagePickerField(
                      imagePath: _imagePath,
                      fallbackEmoji: widget.product?.emoji ??
                          AppConstants.fallbackEmojis.first,
                      onCameraTap: () => _pickImage(ImageSource.camera),
                      onGalleryTap: () => _pickImage(ImageSource.gallery),
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TextInput(
                      controller: _nameController,
                      label: 'Item Name',
                      hintText: 'e.g. Premium Headphones',
                      validator: _validateName,
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TwoColumnFields(
                      first: _TextInput(
                        controller: _buyController,
                        label: 'Buy Price (${AppConstants.currencySymbol})',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: _validateNonNegativeDouble,
                      ),
                      second: _TextInput(
                        controller: _sellController,
                        label: 'Sell Price (${AppConstants.currencySymbol})',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: _validateNonNegativeDouble,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing.md),
                    _ProfitPreview(value: _profitPreview),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TwoColumnFields(
                      first: _TextInput(
                        controller: _stockController,
                        label: 'Stock Qty',
                        hintText: '0',
                        keyboardType: TextInputType.number,
                        validator: _validateNonNegativeInt,
                      ),
                      second: _TextInput(
                        controller: _alertController,
                        label: 'Low Alert at',
                        hintText: '${AppConstants.defaultLowStockAlert}',
                        keyboardType: TextInputType.number,
                        validator: _validatePositiveInt,
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _CategoryDropdown(
                      value: _category,
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _category = value);
                      },
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TextInput(
                      controller: _skuController,
                      label: 'SKU',
                      hintText: 'Optional',
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TextInput(
                      controller: _barcodeController,
                      label: 'Barcode',
                      hintText: 'Enter barcode manually',
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: AppConstants.spacing.xl),
                    _TextInput(
                      controller: _notesController,
                      label: 'Notes',
                      hintText: 'Optional notes',
                      maxLines: 3,
                    ),
                    SizedBox(height: AppConstants.spacing.xxl),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: _isEditMode ? 'Save Changes' : 'Save Item',
                      onPressed: _saveProduct,
                    ),
                    SizedBox(height: AppConstants.spacing.sm),
                    _CancelButton(onPressed: Navigator.of(context).pop),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _populateFields() {
    final Product? product = widget.product;
    if (product == null) {
      _buyController.text = '';
      _sellController.text = '';
      _stockController.text = '';
      _alertController.text = '${AppConstants.defaultLowStockAlert}';
      _updateProfitPreview();
      return;
    }

    _nameController.text = product.name;
    _buyController.text = _formatNumber(product.buyPrice);
    _sellController.text = _formatNumber(product.sellPrice);
    _stockController.text = '${product.stock}';
    _alertController.text = '${product.alertThreshold}';
    _skuController.text = product.sku;
    _barcodeController.text = product.barcode;
    _notesController.text = product.notes;
    _imagePath = product.imagePath;
    _category = _categoryOptions().contains(product.category) ||
            product.category.isEmpty
        ? product.category.isEmpty
            ? AppConstants.productCategories.first
            : product.category
        : AppConstants.productCategories.first;
    _updateProfitPreview();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedFile == null) {
      return;
    }

    final String storedPath = await _copyImageToLocalStorage(pickedFile);
    if (!mounted) {
      return;
    }

    setState(() => _imagePath = storedPath);
  }

  Future<String> _copyImageToLocalStorage(XFile pickedFile) async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory imageDirectory = Directory(
      path.join(appDirectory.path, 'shadow_product_images'),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final String extension = path.extension(pickedFile.path).isEmpty
        ? '.jpg'
        : path.extension(pickedFile.path);
    final String fileName = '${_uuid.v4()}$extension';
    final String destinationPath = path.join(imageDirectory.path, fileName);

    return File(pickedFile.path).copy(destinationPath).then(
          (File file) => file.path,
        );
  }

  Future<void> _saveProduct() async {
    if (_isSaving) {
      return;
    }

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    widget.provider.clearAlert();
    widget.provider.clearError();

    final Product product = _buildProduct();

    if (_isEditMode) {
      await widget.provider.updateProduct(product);
    } else {
      await widget.provider.addProduct(product);
    }

    await widget.provider.loadProducts();
    if (widget.provider.alertMessage == null &&
        widget.provider.errorMessage == null) {
      widget.provider.showAlert(
        _isEditMode ? 'Product updated.' : 'Product added.',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  Product _buildProduct() {
    final Product? existing = widget.product;
    final DateTime now = DateTime.now();
    final double buyPrice = _parseDouble(_buyController.text);
    final double sellPrice = _parseDouble(_sellController.text);

    if (existing != null) {
      return existing.copyWith(
        name: _nameController.text.trim(),
        buyPrice: buyPrice,
        sellPrice: sellPrice,
        stock: _parseInt(_stockController.text),
        alertThreshold: _parseInt(_alertController.text),
        imagePath: _imagePath,
        category: _category,
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        notes: _notesController.text.trim(),
        updatedAt: now,
      );
    }

    return Product(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      stock: _parseInt(_stockController.text),
      alertThreshold: _parseInt(_alertController.text),
      imagePath: _imagePath,
      emoji: _randomFallbackEmoji(),
      category: _category,
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  void _updateProfitPreview() {
    final double buyPrice = _parseDouble(_buyController.text);
    final double sellPrice = _parseDouble(_sellController.text);
    final double profit = sellPrice - buyPrice;

    if (_profitPreview == profit) {
      return;
    }

    setState(() => _profitPreview = profit);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateNonNegativeDouble(String? value) {
    final double? parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Enter 0 or more';
    }
    return null;
  }

  String? _validateNonNegativeInt(String? value) {
    final int? parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Enter 0 or more';
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    final int? parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 1) {
      return 'Enter 1 or more';
    }
    return null;
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return '${value.round()}';
    }
    return '$value';
  }

  String _randomFallbackEmoji() {
    final int index = Random().nextInt(AppConstants.fallbackEmojis.length);
    return AppConstants.fallbackEmojis[index];
  }

  List<String> _categoryOptions() {
    return AppConstants.productCategories;
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: EdgeInsets.only(top: AppConstants.spacing.xl),
      decoration: BoxDecoration(
        color: AppConstants.colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppConstants.radii.sm),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({
    required this.imagePath,
    required this.fallbackEmoji,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final String? imagePath;
  final String fallbackEmoji;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppConstants.colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radii.md),
        border: Border.all(color: AppConstants.colors.border, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacing.md),
        child: Column(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radii.md),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: imagePath == null || imagePath!.isEmpty
                    ? ColoredBox(
                        color: AppConstants.colors.surfaceHigh,
                        child: Center(
                          child: Text(
                            fallbackEmoji,
                            style: const TextStyle(fontSize: 34),
                          ),
                        ),
                      )
                    : Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return ColoredBox(
                            color: AppConstants.colors.surfaceHigh,
                            child: Center(
                              child: Text(
                                fallbackEmoji,
                                style: const TextStyle(fontSize: 34),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            SizedBox(height: AppConstants.spacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCameraTap,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                SizedBox(width: AppConstants.spacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGalleryTap,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({
    required this.first,
    required this.second,
  });

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: <Widget>[
              first,
              SizedBox(height: AppConstants.spacing.xl),
              second,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: first),
            SizedBox(width: AppConstants.spacing.lg),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppConstants.colors.textPrimary,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: AppConstants.colors.surface,
      decoration: const InputDecoration(labelText: 'Category'),
      items: AppConstants.productCategories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
    );
  }
}

class _ProfitPreview extends StatelessWidget {
  const _ProfitPreview({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = value >= 0
        ? AppConstants.colors.green
        : AppConstants.colors.red;

    return AnimatedContainer(
      duration: AppConstants.durations.fast,
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing.xl,
        vertical: AppConstants.spacing.md,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppConstants.radii.md),
        border: Border.all(color: accentColor.withOpacity(0.24)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.trending_up_rounded, color: accentColor, size: 18),
          SizedBox(width: AppConstants.spacing.md),
          Text(
            'Profit Preview',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            '${AppConstants.currencySymbol}${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  final bool isSaving;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.durations.fast,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            AppConstants.colors.gold,
            AppConstants.colors.goldDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radii.lg),
      ),
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: AppConstants.colors.onAccent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radii.lg),
          ),
        ),
        child: AnimatedSwitcher(
          duration: AppConstants.durations.fast,
          child: isSaving
              ? SizedBox.square(
                  key: const ValueKey<String>('saving'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppConstants.colors.onAccent,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey<String>('label'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: const Text('Cancel'),
    );
  }
}