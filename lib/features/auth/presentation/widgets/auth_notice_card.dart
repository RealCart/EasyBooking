import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Neutral note on a surface background, such as the SMS hints on the login
/// and verification screens. `AppCallout` always has a title and a status
/// tone, which these notes do not.
final class AuthNoticeCard extends StatelessWidget {
  const AuthNoticeCard({
    required this.iconPath,
    required this.message,
    super.key,
  });

  final String iconPath;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.media)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.medium,
          children: <Widget>[
            ExcludeSemantics(
              child: SvgPicture.asset(
                iconPath,
                width: AppSizes.iconAction,
                height: AppSizes.iconAction,
                colorFilter: const ColorFilter.mode(
                  AppColors.text,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Expanded(
              child: Text(
                message,
                style: AppTypography.compactBody.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
