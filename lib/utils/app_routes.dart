import 'package:flutter/material.dart';

import '../screens/inventory_screen.dart';
import '../screens/product_details_screen.dart';
import '../models/product.dart';

/// Named routes for the app shell.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String inventory = '/';
  static const String productDetails = '/product-details';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    if (settings.name == productDetails) {
      final Product product = settings.arguments as Product;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => ProductDetailsScreen(product: product),
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) {
        if (settings.name == inventory) {
          return const InventoryScreen();
        }

        return const InventoryScreen();
      },
    );
  }
}