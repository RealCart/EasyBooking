import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.icon,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Widget? icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.media)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 188),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 28,
                child: icon ?? SvgPicture.asset(AppAssets.icons.searchLarge),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.compactBody.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: AppSpacing.small),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.black,
                    overlayColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    textStyle: AppTypography.action.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
