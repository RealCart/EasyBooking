import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';

class AppPropertyRow extends StatelessWidget {
  const AppPropertyRow({
    required this.title,
    required this.imageUrl,
    required this.subtitle,
    required this.price,
    required this.unitLabel,
    required this.status,
    this.isSaved = false,
    this.onSavedPressed,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String imageUrl;
  final String subtitle;
  final String price;
  final String unitLabel;
  final String status;
  final bool isSaved;

  /// Toggles [isSaved]; the heart is hidden when `null`.
  final VoidCallback? onSavedPressed;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.media),
              child: SizedBox.square(
                dimension: 92,
                child: Image.asset(imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.action.copyWith(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: price),
                        TextSpan(text: ' / $unitLabel'),
                      ],
                    ),
                    style: AppTypography.compactBody.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onSavedPressed != null) ...<Widget>[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                child: Center(
                  child: AppSavedIconButton(
                    isSaved: isSaved,
                    onPressed: onSavedPressed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
