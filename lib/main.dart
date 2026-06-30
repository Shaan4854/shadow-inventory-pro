import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'repositories/sqlite_product_repository.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShadowInventoryProApp());
}

class ShadowInventoryProApp extends StatelessWidget {
  const ShadowInventoryProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductProvider>(
      create: (_) => ProductProvider(
        productRepository: SQLiteProductRepository(),
      )..loadProducts(),
      child: MaterialApp(
        title: 'Shadow Inventory Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.inventory,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}