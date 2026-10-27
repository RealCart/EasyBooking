import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppWeekDay {
  const AppWeekDay({
    required this.date,
    required this.weekdayLabel,
    this.semanticLabel,
    this.isEnabled = true,
  });

  final DateTime date;
  final String weekdayLabel;
  final String? semanticLabel;
  final bool isEnabled;

  String get dayLabel => date.day.toString();
}

final class AppWeekSelector extends StatelessWidget {
  const AppWeekSelector({
    required this.days,
    required this.selectedDate,
    required this.onSelected,
    super.key,
  }) : assert(days.length == 7);

  static const double _minimumWidth = AppSizes.touchTarget * 7;

  final List<AppWeekDay> days;
  final DateTime selectedDate;
  final ValueChanged<AppWeekDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = math.max(_minimumWidth, constraints.maxWidth);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: days.map((AppWeekDay day) {
                  final bool isSelected = DateUtils.isSameDay(
                    day.date,
                    selectedDate,
                  );
                  return Expanded(
                    child: _WeekDayButton(
                      day: day,
                      isSelected: isSelected,
                      onPressed: day.isEnabled ? () => onSelected(day) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

final class _WeekDayButton extends StatelessWidget {
  const _WeekDayButton({
    required this.day,
    required this.isSelected,
    required this.onPressed,
  });

  final AppWeekDay day;
  final bool isSelected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = onPressed == null
        ? AppColors.secondaryText.withValues(alpha: 0.4)
        : isSelected
        ? AppColors.background
        : AppColors.text;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: isSelected,
      label: day.semanticLabel ?? '${day.weekdayLabel}, ${day.date.day}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    day.weekdayLabel,
                    maxLines: 1,
                    style: AppTypography.caption.copyWith(
                      color: onPressed == null
                          ? AppColors.secondaryText.withValues(alpha: 0.4)
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : Colors.transparent,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(AppRadii.pill),
                      ),
                    ),
                    child: SizedBox.square(
                      dimension: 30,
                      child: Center(
                        child: Text(
                          day.dayLabel,
                          style: AppTypography.action.copyWith(
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
