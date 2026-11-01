import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// The booking a contract covers: photo, property, dates, and guest, with a
/// chevron that opens the booking.
final class ContractStayCard extends StatelessWidget {
  const ContractStayCard({
    required this.imagePath,
    required this.title,
    required this.dates,
    required this.guestName,
    required this.onTap,
    super.key,
  });

  static const double _imageSize = 72;

  /// An asset path of the property photo.
  final String imagePath;
  final String title;
  final String dates;
  final String guestName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle detailStyle = AppTypography.compactBody.copyWith(
      color: AppColors.secondaryText,
    );
    return Semantics(
      button: true,
      label: 'Открыть бронь',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Image.asset(
                imagePath,
                width: _imageSize,
                height: _imageSize,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.square(
                  dimension: _imageSize,
                  child: ColoredBox(color: AppColors.skeletonImage),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.primaryText.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(dates, style: detailStyle),
                  Text(guestName, style: detailStyle),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
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
    );
  }
}
