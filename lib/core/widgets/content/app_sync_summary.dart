import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppSyncSummary extends StatelessWidget {
  const AppSyncSummary({
    required this.title,
    required this.subtitle,
    super.key,
    this.leading,
    this.action,
    this.onTap,
    this.isSuccessful = true,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onTap;
  final bool isSuccessful;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isSuccessful
        ? AppColors.success
        : AppColors.warning;
    final Color backgroundColor = isSuccessful
        ? AppColors.successSurface
        : AppColors.warningSurface;
    final BorderRadius borderRadius = BorderRadius.circular(16);

    return Material(
      color: backgroundColor,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child:
                        leading ??
                        Icon(
                          isSuccessful
                              ? Icons.sync_rounded
                              : Icons.sync_problem_rounded,
                          color: foregroundColor,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.primaryText.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(child: action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
