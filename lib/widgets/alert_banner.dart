import 'package:flutter/material.dart';

import '../utils/app_constants.dart';

/// Visual treatment for alert messages.
enum AlertBannerType {
  /// Positive feedback.
  success,

  /// Warning feedback.
  warning,

  /// Error feedback.
  error,
}

/// Animated top banner for success, warning, and error messages.
class AlertBanner extends StatelessWidget {
  /// Creates an alert banner.
  const AlertBanner({
    required this.message,
    required this.isVisible,
    this.type = AlertBannerType.warning,
    super.key,
  });

  /// Message to display.
  final String? message;

  /// Whether the banner is visible.
  final bool isVisible;

  /// Banner visual type.
  final AlertBannerType type;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _backgroundColor();
    final Color foregroundColor = _foregroundColor();

    return AnimatedSlide(
      duration: AppConstants.durations.alert,
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, -1.2),
      child: AnimatedOpacity(
        duration: AppConstants.durations.normal,
        opacity: isVisible ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: backgroundColor.withOpacity(0.31),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing.page,
                vertical: AppConstants.spacing.xl,
              ),
              child: Row(
                children: <Widget>[
                  Icon(_icon(), color: foregroundColor, size: 18),
                  SizedBox(width: AppConstants.spacing.md),
                  Expanded(
                    child: Text(
                      message ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor() {
    return switch (type) {
      AlertBannerType.success => AppConstants.colors.green,
      AlertBannerType.warning => AppConstants.colors.gold,
      AlertBannerType.error => AppConstants.colors.red,
    };
  }

  Color _foregroundColor() {
    return switch (type) {
      AlertBannerType.success => AppConstants.colors.onAccent,
      AlertBannerType.warning => AppConstants.colors.onAccent,
      AlertBannerType.error => AppConstants.colors.onDanger,
    };
  }

  IconData _icon() {
    return switch (type) {
      AlertBannerType.success => Icons.check_circle_outline_rounded,
      AlertBannerType.warning => Icons.warning_amber_rounded,
      AlertBannerType.error => Icons.error_outline_rounded,
    };
  }
}
