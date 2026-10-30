import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppStepper extends StatelessWidget {
  const AppStepper({
    required this.value,
    required this.onChanged,
    this.minimum = 0,
    this.maximum = 99,
    this.step = 1,
    this.decreaseLabel = 'Decrease',
    this.increaseLabel = 'Increase',
    super.key,
  }) : assert(minimum <= maximum),
       assert(value >= minimum && value <= maximum),
       assert(step > 0);

  final int value;
  final ValueChanged<int>? onChanged;
  final int minimum;
  final int maximum;
  final int step;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final bool canDecrease = onChanged != null && value > minimum;
    final bool canIncrease = onChanged != null && value < maximum;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepperButton(
          isIncrease: false,
          semanticLabel: decreaseLabel,
          onPressed: canDecrease
              ? () => onChanged!((value - step).clamp(minimum, maximum))
              : null,
        ),
        const SizedBox(width: 12),
        Semantics(
          liveRegion: true,
          label: 'Value $value',
          excludeSemantics: true,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTypography.primaryText.copyWith(color: AppColors.text),
          ),
        ),
        const SizedBox(width: 12),
        _StepperButton(
          isIncrease: true,
          semanticLabel: increaseLabel,
          onPressed: canIncrease
              ? () => onChanged!((value + step).clamp(minimum, maximum))
              : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.isIncrease,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool isIncrease;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: AppSizes.touchTarget,
        child: Opacity(
          opacity: onPressed == null ? 0.4 : 1,
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            icon: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: isIncrease
                  ? SvgPicture.asset(
                      AppAssets.icons.plus,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.text,
                        BlendMode.srcIn,
                      ),
                    )
                  : Text(
                      '−',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.text,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
