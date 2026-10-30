import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/widgets/actions/app_choice_chip.dart';

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
            child: AppChoiceChip(
              label: labels[index],
              isSelected: isSelected,
              onSelected: (bool _) => onSelected(index),
            ),
          );
        }),
      ),
    );
  }
}
