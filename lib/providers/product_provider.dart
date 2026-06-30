import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../models/stock_movement.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/app_constants.dart';
import '../utils/filter_type.dart';
import '../utils/sort_type.dart';

/// Owns inventory application state and coordinates product persistence.
class ProductProvider extends ChangeNotifier {
  /// Creates a provider backed by a product repository abstraction.
  ProductProvider({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  final ProductRepository _productRepository;

  final List<Product> _products = <Product>[];
  final List<String> _categories = <String>[];
  final List<Transaction> _transactions = <Transaction>[];
  final List<StockMovement> _movements = <StockMovement>[];

  FilterType _selectedFilter = FilterType.all;
  SortType _selectedSort = SortType.newest;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _alertMessage;

  /// All products currently loaded from persistence.
  UnmodifiableListView<Product> get products {
    return UnmodifiableListView<Product>(_products);
  }

  /// All dynamic categories loaded from persistence.
  UnmodifiableListView<String> get categories {
    return UnmodifiableListView<String>(_categories);
  }

  /// All transactions loaded from persistence.
  UnmodifiableListView<Transaction> get transactions {
    return UnmodifiableListView<Transaction>(_transactions);
  }

  /// All stock movements loaded from persistence.
  UnmodifiableListView<StockMovement> get movements {
    return UnmodifiableListView<StockMovement>(_movements);
  }

  /// Products after applying the current search query, selected filter, and sort.
  List<Product> get filteredProducts {
    Iterable<Product> visibleProducts = _products;

    if (_searchQuery.isNotEmpty) {
      visibleProducts = visibleProducts.where(_matchesSearch);
    }

    visibleProducts = visibleProducts.where(_matchesFilter);

    final List<Product> sortedList = visibleProducts.toList();
    _applySort(sortedList);

    return List<Product>.unmodifiable(sortedList);
  }

  /// Current inventory filter.
  FilterType get selectedFilter => _selectedFilter;

  /// Current inventory sort.
  SortType get selectedSort => _selectedSort;

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

  /// Total current stock quantity across all products.
  int get totalStock {
    return _products.fold<int>(
        0, (int total, Product product) => total + product.stock,);
  }

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

  /// Total profit from transactions today.
  double get todayProfit {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _transactions
        .where((tx) => tx.createdAt.isAfter(today))
        .where((tx) =>
            tx.type == TransactionType.sale ||
            tx.type == TransactionType.salesReturn,)
        .fold<double>(0.0, (sum, tx) {
      double txProfit = 0;
      for (var item in tx.items) {
        final product = _products.firstWhere((p) => p.id == item.productId,
            orElse: () => _emptyProduct,);
        if (product.id.isNotEmpty) {
          txProfit += (item.priceAtTime - product.buyPrice) * item.quantity;
        }
      }
      if (tx.type == TransactionType.salesReturn) {
        return sum - (txProfit - tx.discount);
      }
      return sum + (txProfit - tx.discount);
    });
  }

  static final Product _emptyProduct = Product(
    id: '',
    name: '',
    buyPrice: 0,
    sellPrice: 0,
    stock: 0,
    alertThreshold: 0,
    emoji: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

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

  /// Loads products, categories, and transactions from the repository.
  Future<void> loadAllData() async {
    _setLoading(true);
    _clearErrorSilently();

    try {
      await _productRepository.seedDatabaseIfEmpty();

      final results = await Future.wait([
        _productRepository.getProducts(),
        _productRepository.getCategories(),
        _productRepository.getTransactions(),
        _productRepository.getStockMovements(),
      ]);

      _replaceProducts(results[0] as List<Product>);

      _categories
        ..clear()
        ..addAll(results[1] as List<String>);

      _transactions
        ..clear()
        ..addAll(results[2] as List<Transaction>);

      _movements
        ..clear()
        ..addAll(results[3] as List<StockMovement>);
    } catch (error) {
      _setError('Unable to load inventory data.');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads products and categories from the repository.
  Future<void> loadProducts() async {
    await loadAllData();
  }

  /// Adds a transaction and refreshes local state.
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearErrorSilently();

    try {
      await _productRepository.addTransaction(transaction);
      // Reload everything to ensure stock and history are synced
      await loadAllData();
      _alertMessage = 'Transaction saved successfully.';
    } catch (error) {
      _setError('Unable to save transaction.');
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a stock movement (manual adjustment) and refreshes local state.
  Future<void> addStockMovement(StockMovement movement) async {
    _setLoading(true);
    _clearErrorSilently();

    try {
      await _productRepository.addStockMovement(movement);
      // Reload everything
      await loadAllData();
      _alertMessage = 'Stock adjusted successfully.';
    } catch (error) {
      _setError('Unable to adjust stock.');
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

      if (product.category.isNotEmpty &&
          !_categories.contains(product.category)) {
        await _productRepository.addCategory(product.category);
        _categories.add(product.category);
      }

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

      if (product.category.isNotEmpty &&
          !_categories.contains(product.category)) {
        await _productRepository.addCategory(product.category);
        _categories.add(product.category);
      }

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

  /// Returns true if the SKU already exists for another product.
  bool isSkuDuplicate(String sku, String? excludeId) {
    if (sku.isEmpty) {
      return false;
    }
    return _products.any((Product p) => p.sku == sku && p.id != excludeId);
  }

  /// Returns true if the barcode already exists for another product.
  bool isBarcodeDuplicate(String barcode, String? excludeId) {
    if (barcode.isEmpty) {
      return false;
    }
    return _products
        .any((Product p) => p.barcode == barcode && p.id != excludeId);
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

  /// Changes the selected inventory sort.
  void setSort(SortType sort) {
    if (_selectedSort == sort) {
      return;
    }

    _selectedSort = sort;
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
    final String sku = product.sku.toLowerCase();
    final String barcode = product.barcode.toLowerCase();

    return name.contains(query) ||
        sku.contains(query) ||
        barcode.contains(query);
  }

  bool _matchesFilter(Product product) {
    return switch (_selectedFilter) {
      FilterType.all => true,
      FilterType.inStock => product.stock > 0,
      FilterType.outOfStock => product.stock == 0,
      FilterType.lowStock => _isLowStock(product),
      FilterType.highStock => product.stock >= AppConstants.highStockThreshold,
    };
  }

  void _applySort(List<Product> list) {
    switch (_selectedSort) {
      case SortType.newest:
        list.sort((Product a, Product b) => b.updatedAt.compareTo(a.updatedAt));
      case SortType.nameAsc:
        list.sort((Product a, Product b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),);
      case SortType.nameDesc:
        list.sort((Product a, Product b) =>
            b.name.toLowerCase().compareTo(a.name.toLowerCase()),);
      case SortType.stockAsc:
        list.sort((Product a, Product b) => a.stock.compareTo(b.stock));
      case SortType.stockDesc:
        list.sort((Product a, Product b) => b.stock.compareTo(a.stock));
      case SortType.priceAsc:
        list.sort((Product a, Product b) => a.sellPrice.compareTo(b.sellPrice));
      case SortType.priceDesc:
        list.sort((Product a, Product b) => b.sellPrice.compareTo(a.sellPrice));
    }
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
