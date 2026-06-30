import 'package:flutter/material.dart';

import '../screens/inventory_screen.dart';

/// Named routes for the app shell.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String inventory = '/';

  static Route<void> onGenerateRoute(RouteSettings settings) {
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