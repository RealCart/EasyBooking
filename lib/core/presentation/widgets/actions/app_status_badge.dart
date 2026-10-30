import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppStatusBadgeVariant { success, warning, error, info, neutral }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.variant = AppStatusBadgeVariant.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppStatusBadgeVariant variant;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color foreground}) colors = switch (variant) {
      AppStatusBadgeVariant.success => (
        background: AppColors.successSurface,
        foreground: AppColors.success,
      ),
      AppStatusBadgeVariant.warning => (
        background: AppColors.warningSurface,
        foreground: AppColors.warning,
      ),
      AppStatusBadgeVariant.error => (
        background: AppColors.errorSurface,
        foreground: AppColors.error,
      ),
      AppStatusBadgeVariant.info => (
        background: AppColors.infoSurface,
        foreground: AppColors.info,
      ),
      AppStatusBadgeVariant.neutral => (
        background: AppColors.surface,
        foreground: AppColors.secondaryText,
      ),
    };

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon case final Widget icon) ...<Widget>[
                IconTheme(
                  data: IconThemeData(color: colors.foreground, size: 14),
                  child: icon,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
