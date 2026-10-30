import 'package:flutter/material.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_header_back_button.dart';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
            child: Row(
              children: <Widget>[
                AppHeaderBackButton(
                  semanticLabel: backSemanticLabel,
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.primaryText.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Semantics(
                    label: '$currentStep of $totalSteps',
                    child: Text(
                      '$currentStep$stepSeparator$totalSteps',
                      textAlign: TextAlign.end,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
