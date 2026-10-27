import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
    super.key,
  }) : assert(
         (actionLabel == null && onAction == null) ||
             (actionLabel != null && onAction != null),
       );

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final String? actionLabel = this.actionLabel;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.text,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(width: AppSpacing.medium),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSizes.touchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                ),
                foregroundColor: AppColors.text,
                textStyle: AppTypography.action,
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
