import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqlite;

import '../models/product.dart';
import '../models/transaction.dart' as model;
import '../models/transaction_item.dart';
import '../models/transaction_type.dart';
import '../models/stock_movement.dart';

/// Handles SQLite database setup, migrations, and low-level product CRUD.
class DatabaseHelper {
  DatabaseHelper._();

  /// Shared database helper instance.
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'shadow_inventory_pro.db';
  static const int databaseVersion = 3;

  static const String productsTable = 'products';
  static const String categoriesTable = 'categories';
  static const String transactionsTable = 'transactions';
  static const String transactionItemsTable = 'transaction_items';
  static const String stockMovementsTable = 'stock_movements';

  sqlite.Database? _database;

  /// Returns the open database, creating it if needed.
  Future<sqlite.Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<sqlite.Database> _openDatabase() async {
    final String databaseDirectory = await sqlite.getDatabasesPath();
    final String databasePath = path.join(databaseDirectory, databaseName);

    return sqlite.openDatabase(
      databasePath,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(sqlite.Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(sqlite.Database db, int version) async {
    await db.execute(_createProductsTableSql);
    await db.execute(_createCategoriesTableSql);
    await db.execute(_createTransactionsTableSql);
    await db.execute(_createTransactionItemsTableSql);
    await db.execute(_createStockMovementsTableSql);
  }

  Future<void> _onUpgrade(
      sqlite.Database db, int oldVersion, int newVersion,) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE $productsTable ADD COLUMN brand TEXT NOT NULL DEFAULT ""',);
      await db.execute(
          'ALTER TABLE $productsTable ADD COLUMN unit TEXT NOT NULL DEFAULT "pcs"',);
      await db.execute(_createCategoriesTableSql);
    }
    if (oldVersion < 3) {
      await db.execute(_createTransactionsTableSql);
      await db.execute(_createTransactionItemsTableSql);
      await db.execute(_createStockMovementsTableSql);
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
  brand TEXT NOT NULL DEFAULT '',
  unit TEXT NOT NULL DEFAULT 'pcs',
  sku TEXT NOT NULL DEFAULT '',
  barcode TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)
''';

  static const String _createCategoriesTableSql = '''
CREATE TABLE $categoriesTable (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''';

  static const String _createTransactionsTableSql = '''
CREATE TABLE $transactionsTable (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  total_amount REAL NOT NULL DEFAULT 0,
  discount REAL NOT NULL DEFAULT 0,
  notes TEXT NOT NULL DEFAULT '',
  payment_method TEXT NOT NULL DEFAULT 'Cash',
  entity_name TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
)
''';

  static const String _createTransactionItemsTableSql = '''
CREATE TABLE $transactionItemsTable (
  id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price_at_time REAL NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES $transactionsTable (id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES $productsTable (id) ON DELETE CASCADE
)
''';

  static const String _createStockMovementsTableSql = '''
CREATE TABLE $stockMovementsTable (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  transaction_id TEXT,
  type TEXT NOT NULL,
  quantity_change INTEGER NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL,
  FOREIGN KEY (product_id) REFERENCES $productsTable (id) ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES $transactionsTable (id) ON DELETE CASCADE
)
''';

  /// Fetches every category.
  Future<List<String>> getCategories() async {
    final sqlite.Database db = await database;
    final List<Map<String, Object?>> maps = await db.query(categoriesTable);
    return maps.map((Map<String, Object?> m) => m['name'] as String).toList();
  }

  /// Inserts a category if it doesn't exist.
  Future<void> insertCategory(String name) async {
    final sqlite.Database db = await database;
    await db.insert(
      categoriesTable,
      <String, Object?>{
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
      },
      conflictAlgorithm: sqlite.ConflictAlgorithm.ignore,
    );
  }

  /// Fetches every product ordered by newest update first.
  Future<List<Product>> getProducts() async {
    final sqlite.Database db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      productsTable,
      orderBy: 'updated_at DESC',
    );

    return maps.map(Product.fromMap).toList();
  }

  /// Fetches one product by id.
  Future<Product?> getProduct(String id) async {
    final sqlite.Database db = await database;
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
    final sqlite.Database db = await database;
    await db.insert(
      productsTable,
      product.toMap(),
      conflictAlgorithm: sqlite.ConflictAlgorithm.abort,
    );
  }

  /// Inserts many products in a single transaction.
  Future<void> insertProducts(List<Product> products) async {
    final sqlite.Database db = await database;
    await db.transaction((sqlite.Transaction txn) async {
      final sqlite.Batch batch = txn.batch();
      for (final Product product in products) {
        batch.insert(
          productsTable,
          product.toMap(),
          conflictAlgorithm: sqlite.ConflictAlgorithm.abort,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates an existing product by id.
  Future<void> updateProduct(Product product) async {
    final sqlite.Database db = await database;
    await db.update(
      productsTable,
      product.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[product.id],
    );
  }

  /// Deletes a product by id.
  Future<void> deleteProduct(String id) async {
    final sqlite.Database db = await database;
    await db.delete(
      productsTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Returns the number of stored products.
  Future<int> countProducts() async {
    final sqlite.Database db = await database;
    final int? count = sqlite.Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $productsTable'),
    );
    return count ?? 0;
  }

  /// Closes the current database connection.
  Future<void> close() async {
    final sqlite.Database? db = _database;
    if (db == null) {
      return;
    }

    await db.close();
    _database = null;
  }

  // --- Transactions ---

  Future<void> insertTransaction(model.Transaction transaction) async {
    final sqlite.Database db = await database;
    await db.transaction((sqlite.Transaction txn) async {
      // 1. Insert Transaction
      await txn.insert(transactionsTable, transaction.toMap());

      // 2. Insert Transaction Items
      for (final item in transaction.items) {
        await txn.insert(transactionItemsTable, item.toMap());

        // 3. Insert Stock Movement
        int quantityChange = 0;
        switch (transaction.type) {
          case TransactionType.purchase:
          case TransactionType.salesReturn:
            quantityChange = item.quantity;
            break;
          case TransactionType.sale:
          case TransactionType.purchaseReturn:
            quantityChange = -item.quantity;
            break;
          case TransactionType.adjustment:
            quantityChange =
                item.quantity; // Adjustment model should define sign
            break;
        }

        final String movementId =
            DateTime.now().microsecondsSinceEpoch.toString();
        await txn.insert(stockMovementsTable, {
          'id': movementId,
          'product_id': item.productId,
          'transaction_id': transaction.id,
          'type': transaction.type.name,
          'quantity_change': quantityChange,
          'reason': transaction.notes,
          'created_at': transaction.createdAt.millisecondsSinceEpoch,
        });

        // 4. Update Product Stock
        await txn.rawUpdate(
          'UPDATE $productsTable SET stock = stock + ?, updated_at = ? WHERE id = ?',
          [
            quantityChange,
            transaction.createdAt.millisecondsSinceEpoch,
            item.productId,
          ],
        );
      }
    });
  }

  Future<List<model.Transaction>> getTransactions() async {
    final sqlite.Database db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      transactionsTable,
      orderBy: 'created_at DESC',
    );

    final List<model.Transaction> transactions = [];
    for (final map in maps) {
      final String transactionId = map['id'] as String;
      final List<Map<String, Object?>> itemMaps = await db.rawQuery('''
        SELECT ti.*, p.name as product_name, p.emoji as product_emoji, p.unit as product_unit
        FROM $transactionItemsTable ti
        JOIN $productsTable p ON ti.product_id = p.id
        WHERE ti.transaction_id = ?
      ''', [transactionId],);

      final items = itemMaps
          .map((m) => TransactionItem.fromMap(
                m,
                productName: m['product_name'] as String?,
                productEmoji: m['product_emoji'] as String?,
                productUnit: m['product_unit'] as String?,
              ),)
          .toList();

      transactions.add(model.Transaction.fromMap(map, items: items));
    }
    return transactions;
  }

  // --- Stock Movements ---

  Future<void> insertStockMovement(StockMovement movement) async {
    final sqlite.Database db = await database;
    await db.transaction((sqlite.Transaction txn) async {
      await txn.insert(stockMovementsTable, movement.toMap());
      await txn.rawUpdate(
        'UPDATE $productsTable SET stock = stock + ?, updated_at = ? WHERE id = ?',
        [
          movement.quantityChange,
          movement.createdAt.millisecondsSinceEpoch,
          movement.productId,
        ],
      );
    });
  }

  Future<List<StockMovement>> getStockMovements({String? productId}) async {
    final sqlite.Database db = await database;
    String query = '''
      SELECT sm.*, p.name as product_name, p.emoji as product_emoji
      FROM $stockMovementsTable sm
      JOIN $productsTable p ON sm.product_id = p.id
    ''';
    List<Object?> args = [];

    if (productId != null) {
      query += ' WHERE sm.product_id = ?';
      args.add(productId);
    }

    query += ' ORDER BY sm.created_at DESC';

    final List<Map<String, Object?>> maps = await db.rawQuery(query, args);
    return maps
        .map((m) => StockMovement.fromMap(
              m,
              productName: m['product_name'] as String?,
              productEmoji: m['product_emoji'] as String?,
            ),)
        .toList();
  }
}
