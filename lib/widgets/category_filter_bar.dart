import 'package:flutter/material.dart';

import '../utils/app_constants.dart';
import '../utils/filter_type.dart';

/// Horizontal product filter chips using [FilterType] values.
class CategoryFilterBar extends StatelessWidget {
  /// Creates a filter bar.
  const CategoryFilterBar({
    required this.selectedFilter,
    required this.onFilterSelected,
    super.key,
  });

  /// Currently active filter.
  final FilterType selectedFilter;

  /// Called when the user selects a filter.
  final ValueChanged<FilterType> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FilterType.values.length,
        separatorBuilder: (_, __) => SizedBox(width: AppConstants.spacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final FilterType filter = FilterType.values[index];
          final bool isSelected = filter == selectedFilter;

          return ChoiceChip(
            label: Text(_labelFor(filter)),
            selected: isSelected,
            onSelected: (_) => onFilterSelected(filter),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            backgroundColor: AppConstants.colors.surface,
            selectedColor: AppConstants.colors.primary,
            side: BorderSide(
              color: isSelected
                  ? AppConstants.colors.primary
                  : AppConstants.colors.border,
            ),
            labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppConstants.colors.onAccent
                      : AppConstants.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radii.pill),
            ),
          );
        },
      ),
    );
  }

  String _labelFor(FilterType filter) {
    return switch (filter) {
      FilterType.all => '✨ All',
      FilterType.inStock => '🟡 In Stock',
      FilterType.outOfStock => '🔴 Out of Stock',
      FilterType.highStock => '🔵 High (20+)',
      FilterType.lowStock => '🟡 Low Stock',
    };
  }
}
