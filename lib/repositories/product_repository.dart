import '../models/product.dart';

/// Persistence boundary for inventory products.
///
/// UI and state-management layers should depend on this abstraction so SQLite
/// can later be replaced or complemented by Firebase without changing callers.
abstract class ProductRepository {
  /// Returns all products.
  Future<List<Product>> getProducts();

  /// Returns a single product by id, or null when it does not exist.
  Future<Product?> getProduct(String id);

  /// Persists a new product.
  Future<void> addProduct(Product product);

  /// Persists changes to an existing product.
  Future<void> updateProduct(Product product);

  /// Removes a product by id.
  Future<void> deleteProduct(String id);

  /// Adds starter products only when the product table is empty.
  Future<void> seedDatabaseIfEmpty();
}
