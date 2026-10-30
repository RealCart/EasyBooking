import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
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

  static const double _dayWidth = 48;
  static const double _minimumWidth = _dayWidth * 7;

  final List<AppWeekDay> days;
  final DateTime selectedDate;
  final ValueChanged<AppWeekDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? math.max(_minimumWidth, constraints.maxWidth)
            : _minimumWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: days.map((AppWeekDay day) {
                final bool isSelected = DateUtils.isSameDay(
                  day.date,
                  selectedDate,
                );
                return SizedBox(
                  width: _dayWidth,
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
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.text : Colors.transparent,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadii.pill),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 68,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    day.weekdayLabel,
                    maxLines: 1,
                    style: AppTypography.caption.copyWith(
                      color: onPressed == null
                          ? AppColors.secondaryText.withValues(alpha: 0.4)
                          : isSelected
                          ? AppColors.background
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.dayLabel,
                    style: AppTypography.bodyLarge.copyWith(
                      color: foregroundColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
