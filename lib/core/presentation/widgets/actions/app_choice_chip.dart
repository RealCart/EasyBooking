import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected ? AppColors.onAccent : AppColors.text;

    return GestureDetector(
      onTap: () => onSelected!(!isSelected),
      excludeFromSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          color: isSelected ? AppColors.text : AppColors.surface,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16.0,
          ),
          child: Text(
            label,
            style: AppTypography.compactBody.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
