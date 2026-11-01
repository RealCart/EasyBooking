import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// The apartment of a booking between two dividers: an initials tile, the
/// apartment and the check-in and check-out times. Opens the apartment.
final class BookingApartmentRow extends StatelessWidget {
  const BookingApartmentRow({
    required this.title,
    required this.subtitle,
    required this.initials,
    required this.onTap,
    super.key,
  });

  static const double _tileSize = 64;

  /// `Esentai City · 84`
  final String title;

  /// `Заезд 14:00 · выезд 12:00`
  final String subtitle;

  /// `EC`
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              spacing: 14,
              children: <Widget>[
                SizedBox.square(
                  dimension: _tileSize,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadii.media),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTypography.compactBody.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.action.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.compactBody.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  AppAssets.icons.chevronRight,
                  width: AppSizes.iconAction,
                  height: AppSizes.iconAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
