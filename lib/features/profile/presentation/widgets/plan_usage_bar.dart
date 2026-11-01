import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A plan limit, such as «Объекты 4 из 10», with a progress bar.
final class PlanUsageBar extends StatelessWidget {
  const PlanUsageBar({
    required this.label,
    required this.valueLabel,
    required this.fraction,
    this.isAtLimit = false,
    super.key,
  });

  static const double _barHeight = 5;

  final String label;

  /// Such as `4 из 10`.
  final String valueLabel;

  /// From 0 to 1.
  final double fraction;

  /// Colors the bar as a warning.
  final bool isAtLimit;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.compactBody.copyWith(height: 16 / 13);
    return Semantics(
      label: '$label, $valueLabel',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: style.copyWith(color: AppColors.text),
                ),
              ),
              Text(
                valueLabel,
                style: style.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.pill),
            ),
            child: SizedBox(
              height: _barHeight,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const ColoredBox(color: AppColors.border),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0, 1),
                    child: ColoredBox(
                      color: isAtLimit ? AppColors.warning : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
