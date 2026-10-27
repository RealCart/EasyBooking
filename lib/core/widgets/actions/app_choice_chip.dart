import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.enabled = true,
    this.leading,
    super.key,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final bool enabled;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ChoiceChip(
        avatar: leading,
        label: Text(label),
        selected: isSelected,
        onSelected: enabled ? onSelected : null,
        showCheckmark: false,
        backgroundColor: AppColors.background,
        disabledColor: AppColors.surface,
        selectedColor: AppColors.accent,
        side: BorderSide(
          color: isSelected ? AppColors.accent : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: AppTypography.action.copyWith(
          color: isSelected ? AppColors.onAccent : AppColors.text,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
