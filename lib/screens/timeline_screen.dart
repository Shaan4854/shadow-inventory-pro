import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/timeline_tile.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final movements = provider.movements;

    return Scaffold(
      backgroundColor: AppConstants.colors.background,
      appBar: AppBar(
        title: const Text('INVENTORY TIMELINE'),
      ),
      body: movements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppConstants.colors.textMuted.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Text('No stock movements recorded yet.', style: TextStyle(color: AppConstants.colors.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppConstants.spacing.page),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                return TimelineTile(movement: movements[index]);
              },
            ),
    );
  }
}
