import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../screens/inventory_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/purchase_return_screen.dart';
import '../screens/purchase_screen.dart';
import '../screens/sales_return_screen.dart';
import '../screens/stock_adjustment_screen.dart';
import '../screens/stock_history_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/transaction_details_screen.dart';

/// Named routes for the app shell.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String inventory = '/';
  static const String productDetails = '/product-details';
  static const String purchase = '/purchase';
  static const String pos = '/pos';
  static const String purchaseReturn = '/purchase-return';
  static const String salesReturn = '/sales-return';
  static const String stockAdjustment = '/stock-adjustment';
  static const String stockHistory = '/stock-history';
  static const String timeline = '/timeline';
  static const String transactionDetails = '/transaction-details';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      productDetails => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ProductDetailsScreen(product: settings.arguments as Product),
        ),
      purchase => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PurchaseScreen(),
        ),
      pos => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PosScreen(),
        ),
      purchaseReturn => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const PurchaseReturnScreen(),
        ),
      salesReturn => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SalesReturnScreen(),
        ),
      stockAdjustment => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => StockAdjustmentScreen(product: settings.arguments as Product?),
        ),
      stockHistory => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => StockHistoryScreen(product: settings.arguments as Product),
        ),
      timeline => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const TimelineScreen(),
        ),
      transactionDetails => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => TransactionDetailsScreen(transaction: settings.arguments as Transaction),
        ),
      _ => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const InventoryScreen(),
        ),
    };
  }
}
