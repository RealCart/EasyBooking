import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppScopeFilter extends StatelessWidget {
  const AppScopeFilter({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xLarge,
    ),
    super.key,
  }) : assert(labels.length > 0),
       assert(selectedIndex >= 0),
       assert(selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: List<Widget>.generate(labels.length, (int index) {
          final bool isSelected = selectedIndex == index;
          return Padding(
            padding: EdgeInsetsDirectional.only(
              end: index == labels.length - 1 ? 0 : AppSpacing.small,
            ),
            child: Semantics(
              button: true,
              selected: isSelected,
              child: Material(
                color: isSelected ? AppColors.text : AppColors.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.pill),
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.pill),
                  ),
                  onTap: () => onSelected(index),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.touchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.large,
                        vertical: AppSpacing.small,
                      ),
                      child: Center(
                        child: Text(
                          labels[index],
                          style: AppTypography.action.copyWith(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
