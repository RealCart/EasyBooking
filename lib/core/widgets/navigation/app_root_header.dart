import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppRootHeader extends StatelessWidget {
  const AppRootHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.xLarge,
      AppSpacing.large,
      AppSpacing.xLarge,
      AppSpacing.medium,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final Widget? action = this.action;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.screenTitle.copyWith(
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
          if (action != null) ...<Widget>[
            const SizedBox(width: AppSpacing.medium),
            action,
          ],
        ],
      ),
    );
  }
}
