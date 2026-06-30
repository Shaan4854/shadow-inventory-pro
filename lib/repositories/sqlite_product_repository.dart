import '../database/database_helper.dart';
import '../models/product.dart';
import '../utils/seed_data.dart';
import 'product_repository.dart';

/// SQLite-backed implementation of [ProductRepository].
class SQLiteProductRepository implements ProductRepository {
  /// Creates a repository backed by [databaseHelper].
  SQLiteProductRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<Product>> getProducts() async {
    return _databaseHelper.getProducts();
  }

  @override
  Future<Product?> getProduct(String id) async {
    return _databaseHelper.getProduct(id);
  }

  @override
  Future<void> addProduct(Product product) async {
    await _databaseHelper.insertProduct(product);
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _databaseHelper.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _databaseHelper.deleteProduct(id);
  }

  @override
  Future<void> seedDatabaseIfEmpty() async {
    final int productCount = await _databaseHelper.countProducts();
    if (productCount > 0) {
      return;
    }

    await _databaseHelper.insertProducts(SeedData.initialProducts());
  }
}
