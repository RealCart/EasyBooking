import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// One row of «Управление объектом»: a short glyph in a tile, a title, a
/// summary, and a chevron or a short [trailingText].
final class PropertySettingsRow extends StatelessWidget {
  const PropertySettingsRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
    super.key,
  });

  /// `i`, `₸`, or a count such as `12`.
  final String glyph;
  final String title;
  final String subtitle;

  /// Replaces the chevron, such as `Проверить`.
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? trailingText = this.trailingText;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageGutter,
              vertical: 14,
            ),
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      glyph,
                      maxLines: 1,
                      style: AppTypography.action.copyWith(
                        color: AppColors.text,
                        height: 18 / 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.action.copyWith(
                          color: AppColors.text,
                          height: 18 / 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                      height: 16 / 12,
                    ),
                  )
                else
                  ExcludeSemantics(
                    child: SvgPicture.asset(
                      AppAssets.icons.chevronRight,
                      width: AppSizes.iconInline,
                      height: AppSizes.iconInline,
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
