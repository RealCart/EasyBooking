import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppArrivalCard extends StatelessWidget {
  const AppArrivalCard({
    required this.time,
    required this.propertyName,
    required this.stayDetails,
    this.status,
    this.onTap,
    super.key,
  });

  final String time;
  final String propertyName;
  final String stayDetails;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: const ColoredBox(color: AppColors.surface),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        time,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              propertyName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.action.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 2),
            Text(
              stayDetails,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.compactBody.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(height: 2),
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    AppAssets.icons.checkSmall,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      status!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
