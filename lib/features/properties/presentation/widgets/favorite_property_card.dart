import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';

/// A square photo with a filled heart, the name, today's status, and the
/// price, for the «Избранные» grid.
final class FavoritePropertyCard extends StatelessWidget {
  const FavoritePropertyCard({
    required this.property,
    required this.onTap,
    required this.onSavedPressed,
    super.key,
  });

  final PropertyEntity property;
  final VoidCallback onTap;
  final VoidCallback onSavedPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Stack(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  child: Image.asset(
                    property.imageUrls.first,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: AppSavedIconButton(
                  isSaved: property.isFavorite,
                  onPressed: onSavedPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            property.shortTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.action.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 2),
          Text(
            property.availability.status(short: true),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            property.pricePerNightLabel,
            style: AppTypography.compactBody.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
