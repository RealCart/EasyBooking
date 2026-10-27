import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppProgressAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AppProgressAppBar({
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    this.backSemanticLabel = 'Back',
    this.stepSeparator = ' из ',
    this.showDivider = true,
    super.key,
  }) : assert(currentStep > 0),
       assert(totalSteps > 0),
       assert(currentStep <= totalSteps);

  static const double _height = 56;

  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final String backSemanticLabel;
  final String stepSeparator;
  final bool showDivider;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: SizedBox(
          height: _height,
          child: Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: backSemanticLabel,
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: AppSizes.touchTarget,
                    height: AppSizes.touchTarget,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: backSemanticLabel,
                  onPressed: onBack,
                  icon: SvgPicture.asset(
                    AppAssets.icons.chevronLeft,
                    width: AppSizes.iconAppBar,
                    height: AppSizes.iconAppBar,
                    colorFilter: const ColorFilter.mode(
                      AppColors.text,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.primaryText.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Semantics(
                label: '$currentStep of $totalSteps',
                child: Text(
                  '$currentStep$stepSeparator$totalSteps',
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}
