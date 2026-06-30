import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

/// Rounded search input styled after the original Shadow search bar.
class SearchBarWidget extends StatelessWidget {
  /// Creates a search bar.
  const SearchBarWidget({
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.hintText = 'Search items...',
    super.key,
  });

  /// Optional controller owned by the parent.
  final TextEditingController? controller;

  /// Optional focus node to control autofocus.
  final FocusNode? focusNode;

  /// Called whenever the search text changes.
  final ValueChanged<String> onChanged;

  /// Placeholder text.
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      autofocus: false,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppConstants.colors.textPrimary,
          ),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(
          Icons.search,
          color: AppConstants.colors.textMuted,
          size: 20,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing.xl,
          vertical: AppConstants.spacing.md,
        ),
      ),
    );
  }
}
