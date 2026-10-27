import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppTabs extends StatelessWidget {
  const AppTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(labels.length > 1),
       assert(selectedIndex >= 0),
       assert(selectedIndex < labels.length);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List<Widget>.generate(labels.length, (int index) {
            final bool isSelected = selectedIndex == index;
            return Expanded(
              child: Semantics(
                button: true,
                selected: isSelected,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTypography.action.copyWith(
                              color: isSelected
                                  ? AppColors.text
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const PositionedDirectional(
                            start: 0,
                            end: 0,
                            bottom: 0,
                            child: SizedBox(
                              height: 2,
                              child: ColoredBox(color: AppColors.accent),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
