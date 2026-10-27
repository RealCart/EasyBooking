import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIconButton(
            icon: const Icon(Icons.remove, size: 20),
            semanticLabel: decreaseLabel,
            onPressed: canDecrease
                ? () => onChanged!(
                    (value - step).clamp(minimum, maximum),
                  )
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: Semantics(
              liveRegion: true,
              label: 'Value $value',
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTypography.primaryText.copyWith(
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          AppIconButton(
            icon: const Icon(Icons.add, size: 20),
            semanticLabel: increaseLabel,
            onPressed: canIncrease
                ? () => onChanged!(
                    (value + step).clamp(minimum, maximum),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
