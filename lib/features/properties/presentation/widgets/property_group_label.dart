import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// An uppercase label above a group of rows, such as `ОКТЯБРЬ` or `ДОСТУП`.
final class PropertyGroupLabel extends StatelessWidget {
  const PropertyGroupLabel({
    required this.label,
    this.topPadding = AppSpacing.small,
    super.key,
  });

  final String label;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        topPadding,
        AppSizes.pageGutter,
        AppSpacing.small,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
            height: 16 / 12,
          ),
        ),
      ),
    );
  }
}
