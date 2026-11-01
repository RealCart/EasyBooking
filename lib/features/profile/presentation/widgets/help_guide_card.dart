import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A «Быстрые инструкции» card: the reading time above the title.
final class HelpGuideCard extends StatelessWidget {
  const HelpGuideCard({
    required this.title,
    required this.readingTime,
    required this.onTap,
    super.key,
  });

  static const double _width = 186;
  static const double _minHeight = 104;

  final String title;

  /// Such as `4 минуты`.
  final String readingTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: _width,
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadii.field),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 12,
              children: <Widget>[
                Text(
                  readingTime,
                  style: AppTypography.caption.copyWith(
                    height: 16 / 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 19 / 14,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
