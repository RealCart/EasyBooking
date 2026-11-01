import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Equal-width segments on a grey track; the selected one is filled dark.
final class GuestsSegmentedControl extends StatelessWidget {
  const GuestsSegmentedControl({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  }) : assert(labels.length > 1),
       assert(selectedIndex >= 0),
       assert(selectedIndex < labels.length);

  static const double _segmentHeight = 36;

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // The track radius is the segment radius plus the track padding, so the
    // corners stay concentric.
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(
          Radius.circular(AppRadii.field + AppSpacing.xSmall),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xSmall),
        child: Row(
          children: <Widget>[
            for (int index = 0; index < labels.length; index++)
              Expanded(
                child: _Segment(
                  label: labels[index],
                  isSelected: index == selectedIndex,
                  height: _segmentHeight,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: height),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.text : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.field),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.compactBody.copyWith(
              height: 16 / 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.onAccent : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
