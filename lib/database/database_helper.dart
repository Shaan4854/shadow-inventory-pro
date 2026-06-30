import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

/// Handles SQLite database setup, migrations, and low-level product CRUD.
class DatabaseHelper {
  DatabaseHelper._();

  /// Shared database helper instance.
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'shadow_inventory_pro.db';
  static const int databaseVersion = 1;

  static const String productsTable = 'products';

  Database? _database;

  /// Returns the open database, creating it if needed.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final String databaseDirectory = await getDatabasesPath();
    final String databasePath = path.join(databaseDirectory, databaseName);

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createProductsTableSql);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Future migrations start here.
    }
  }

  static const String _createProductsTableSql = '''
CREATE TABLE $productsTable (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  buy_price REAL NOT NULL DEFAULT 0,
  sell_price REAL NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  alert_threshold INTEGER NOT NULL DEFAULT 5,
  image_path TEXT,
  emoji TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT '',
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''';

  /// Fetches every product ordered by newest update first.
  Future<List<Product>> getProducts() async {
    final Database db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      productsTable,
      orderBy: 'updated_at DESC',
    );

    return maps.map(Product.fromMap).toList();
  }

  /// Fetches one product by id.
  Future<Product?> getProduct(String id) async {
    final Database db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      productsTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Product.fromMap(maps.first);
  }

  /// Inserts a product.
  Future<void> insertProduct(Product product) async {
    final Database db = await database;
    await db.insert(
      productsTable,
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Inserts many products in a single transaction.
  Future<void> insertProducts(List<Product> products) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Product product in products) {
        batch.insert(
          productsTable,
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates an existing product by id.
  Future<void> updateProduct(Product product) async {
    final Database db = await database;
    await db.update(
      productsTable,
      product.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
  }

  /// Deletes a product by id.
  Future<void> deleteProduct(String id) async {
    final Database db = await database;
    await db.delete(
      productsTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Returns the number of stored products.
  Future<int> countProducts() async {
    final Database db = await database;
    final int? count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $productsTable'),
    );
    return count ?? 0;
  }

  /// Closes the current database connection.
  Future<void> close() async {
    final Database? db = _database;
    if (db == null) {
      return;
    }

    await db.close();
    _database = null;
  }
}
