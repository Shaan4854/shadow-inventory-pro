import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../utils/app_constants.dart';
import '../utils/filter_type.dart';

/// Owns inventory application state and coordinates product persistence.
class ProductProvider extends ChangeNotifier {
  /// Creates a provider backed by a product repository abstraction.
  ProductProvider({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final List<Product> _products = <Product>[];
  FilterType _selectedFilter = FilterType.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _alertMessage;

  /// All products currently loaded from persistence.
  UnmodifiableListView<Product> get products {
    return UnmodifiableListView<Product>(_products);
  }

  /// Products after applying the current search query and selected filter.
  List<Product> get filteredProducts {
    Iterable<Product> visibleProducts = _products;

    if (_searchQuery.isNotEmpty) {
      visibleProducts = visibleProducts.where(_matchesSearch);
    }

    visibleProducts = visibleProducts.where(_matchesFilter);

    return List<Product>.unmodifiable(visibleProducts);
  }

  /// Current inventory filter.
  FilterType get selectedFilter => _selectedFilter;

  /// Current search text.
  String get searchQuery => _searchQuery;

  /// True while an async repository operation is running.
  bool get isLoading => _isLoading;

  /// Last recoverable error message, if any.
  String? get errorMessage => _errorMessage;

  /// Last user-facing alert message, if any.
  String? get alertMessage => _alertMessage;

  /// Total number of products.
  int get totalItems => _products.length;

  /// Total current purchase value of stock.
  double get totalBuyValue {
    return _products.fold<double>(
      0,
      (double total, Product product) {
        return total + (product.buyPrice * product.stock);
      },
    );
  }

  /// Total current selling value of stock.
  double get totalSellValue {
    return _products.fold<double>(
      0,
      (double total, Product product) {
        return total + (product.sellPrice * product.stock);
      },
    );
  }

  /// Total projected profit for current stock.
  double get totalProfit => totalSellValue - totalBuyValue;

  /// Number of products with zero stock.
  int get outOfStockCount {
    return _products.where((Product product) => product.stock == 0).length;
  }

  /// Number of products below their own low-stock alert threshold.
  int get lowStockCount {
    return _products.where(_isLowStock).length;
  }

  /// Returns the unit profit for a product.
  double unitProfit(Product product) {
    return product.sellPrice - product.buyPrice;
  }

  /// Returns true when a product has zero stock.
  bool isOutOfStock(Product product) {
    return product.stock == 0;
  }

  /// Returns true when a product is below its own alert threshold.
  bool isLowStock(Product product) {
    return _isLowStock(product);
  }

  /// Loads products from the repository after seeding an empty database.
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearErrorSilently();

    try {
      await _productRepository.seedDatabaseIfEmpty();
      final List<Product> loadedProducts =
          await _productRepository.getProducts();
      _replaceProducts(loadedProducts);
    } catch (error) {
      _setError('Unable to load products.');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a product and refreshes local state.
  Future<void> addProduct(Product product) async {
    _clearErrorSilently();

    try {
      await _productRepository.addProduct(product);
      _products.insert(0, product);
      _setLowStockAlertIfNeeded(product);
      notifyListeners();
    } catch (error) {
      _setError('Unable to add product.');
    }
  }

  /// Updates a product and refreshes local state.
  Future<void> updateProduct(Product product) async {
    _clearErrorSilently();

    try {
      final int index = _products.indexWhere(
        (Product item) => item.id == product.id,
      );

      if (index != -1) {
        final Product oldProduct = _products[index];
        if (oldProduct.imagePath != null &&
            oldProduct.imagePath != product.imagePath) {
          _deleteImageFile(oldProduct.imagePath);
        }
        _products[index] = product;
      } else {
        _products.insert(0, product);
      }

      await _productRepository.updateProduct(product);
      _setLowStockAlertIfNeeded(product);
      notifyListeners();
    } catch (error) {
      _setError('Unable to update product.');
    }
  }

  /// Deletes a product and refreshes local state.
  Future<void> deleteProduct(String productId) async {
    _clearErrorSilently();

    try {
      final int index = _products.indexWhere(
        (Product product) => product.id == productId,
      );

      if (index != -1) {
        final Product product = _products[index];
        if (product.imagePath != null) {
          _deleteImageFile(product.imagePath);
        }
        _products.removeAt(index);
      }

      await _productRepository.deleteProduct(productId);
      notifyListeners();
    } catch (error) {
      _setError('Unable to delete product.');
    }
  }

  void _deleteImageFile(String? path) {
    if (path == null || path.isEmpty) {
      return;
    }

    try {
      final File file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (error) {
      debugPrint('Error deleting image file: $error');
    }
  }

  /// Updates the case-insensitive product search query.
  void search(String query) {
    final String normalizedQuery = query.trim();
    if (_searchQuery == normalizedQuery) {
      return;
    }

    _searchQuery = normalizedQuery;
    notifyListeners();
  }

  /// Changes the selected inventory filter.
  void setFilter(FilterType filter) {
    if (_selectedFilter == filter) {
      return;
    }

    _selectedFilter = filter;
    notifyListeners();
  }

  /// Clears the current alert message.
  void clearAlert() {
    if (_alertMessage == null) {
      return;
    }

    _alertMessage = null;
    notifyListeners();
  }

  /// Sets a new alert message and notifies listeners.
  void showAlert(String message) {
    _alertMessage = message;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  bool _matchesSearch(Product product) {
    final String query = _searchQuery.toLowerCase();
    final String name = product.name.toLowerCase();

    // Future barcode search can be added here without changing the UI layer.
    return name.contains(query);
  }

  bool _matchesFilter(Product product) {
    return switch (_selectedFilter) {
      FilterType.all => true,
      FilterType.inStock => product.stock > 0,
      FilterType.outOfStock => product.stock == 0,
      FilterType.lowStock => _isLowStock(product),
      FilterType.highStock =>
        product.stock >= AppConstants.highStockThreshold,
    };
  }

  bool _isLowStock(Product product) {
    return product.stock > 0 && product.stock < product.alertThreshold;
  }

  void _setLowStockAlertIfNeeded(Product product) {
    if (!_isLowStock(product)) {
      return;
    }

    _alertMessage = '${product.name} is low - only ${product.stock} left!';
  }

  void _replaceProducts(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearErrorSilently() {
    _errorMessage = null;
  }
}