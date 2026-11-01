import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/occupancy_labels.dart';

/// Width of the property column on «Занятость»; the days share the rest.
const double _propertyColumnWidth = 116;

/// The column titles of the occupancy grid: «Объект» and the seven days,
/// with today on a dark pill.
final class OccupancyDaysHeader extends StatelessWidget {
  const OccupancyDaysHeader({required this.days, this.today, super.key})
    : assert(days.length == DateTime.daysPerWeek);

  final List<DateTime> days;

  /// Highlighted when it is one of [days].
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final DateTime? today = this.today;
    final TextStyle style = AppTypography.caption.copyWith(height: 16 / 12);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _propertyColumnWidth,
            child: Text(
              'Объект',
              style: style.copyWith(color: AppColors.secondaryText),
            ),
          ),
          for (final DateTime day in days)
            Expanded(
              child: _DayLabel(
                day: day,
                isToday: today != null && DateUtils.isSameDay(day, today),
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

final class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.day,
    required this.isToday,
    required this.style,
  });

  final DateTime day;
  final bool isToday;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      '${DateFormatter.weekdayShort(day)}\n${day.day}',
      textAlign: TextAlign.center,
      style: style.copyWith(
        color: isToday ? AppColors.onAccent : AppColors.secondaryText,
      ),
    );
    return Semantics(
      label: DateFormatter.dayMonthWeekday(day),
      selected: isToday,
      excludeSemantics: true,
      child: Center(
        child: isToday
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 42),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.text,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadii.pill),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SizedBox(width: double.infinity, child: label),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: label,
              ),
      ),
    );
  }
}

/// One property's line on «Занятость»: its name and price, and its stays
/// and closed dates as bars on a seven-day track. Bars that start before
/// or end after the week are cut at its edges.
final class OccupancyPropertyRow extends StatelessWidget {
  const OccupancyPropertyRow({
    required this.row,
    required this.weekStart,
    required this.onBlockTap,
    this.showBottomDivider = false,
    super.key,
  });

  final OccupancyRowEntity row;

  /// Monday of the week, at midnight.
  final DateTime weekStart;

  /// Called for blocks that open something: a stay or a conflict.
  final ValueChanged<OccupancyBlockEntity> onBlockTap;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.border),
          bottom: showBottomDivider
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 104),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _propertyColumnWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      row.shortTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        height: 16 / 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      row.priceLabel,
                      style: AppTypography.caption.copyWith(
                        height: 16 / 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _Track(
                blocks: row.blocks,
                weekStart: weekStart,
                onBlockTap: onBlockTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Track extends StatelessWidget {
  const _Track({
    required this.blocks,
    required this.weekStart,
    required this.onBlockTap,
  });

  static const double _barInset = 8;
  static const double _barGap = 1;
  static const double _minutesPerDay = 24 * 60;

  final List<OccupancyBlockEntity> blocks;
  final DateTime weekStart;
  final ValueChanged<OccupancyBlockEntity> onBlockTap;

  @override
  Widget build(BuildContext context) {
    // Two 16 px lines and the bar padding, grown with the text size.
    final double barHeight =
        MediaQuery.textScalerOf(context).scale(16) * 2 + 10;
    final double height = math.max(58, barHeight + _barInset * 2);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double dayWidth = constraints.maxWidth / DateTime.daysPerWeek;
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                for (final OccupancyBlockEntity block in blocks)
                  if (_span(block) case (final double from, final double to)
                      when to > from)
                    Positioned(
                      left: from * dayWidth + _barGap,
                      width: math.max(0, (to - from) * dayWidth - _barGap * 2),
                      top: _barInset,
                      bottom: _barInset,
                      child: _BlockBar(
                        block: block,
                        isCutAtStart:
                            from == 0 && block.start.isBefore(weekStart),
                        isCutAtEnd:
                            to == DateTime.daysPerWeek &&
                            block.end.isAfter(_weekEnd),
                        onTap:
                            block.conflictId != null || block.bookingId != null
                            ? () => onBlockTap(block)
                            : null,
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  DateTime get _weekEnd {
    return DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + DateTime.daysPerWeek,
    );
  }

  /// The block's start and end in days from Monday, cut to the week.
  (double, double) _span(OccupancyBlockEntity block) {
    double offset(DateTime at) {
      final double days = at.difference(weekStart).inMinutes / _minutesPerDay;
      return days.clamp(0, DateTime.daysPerWeek.toDouble());
    }

    return (offset(block.start), offset(block.end));
  }
}

final class _BlockBar extends StatelessWidget {
  const _BlockBar({
    required this.block,
    required this.isCutAtStart,
    required this.isCutAtEnd,
    required this.onTap,
  });

  final OccupancyBlockEntity block;
  final bool isCutAtStart;
  final bool isCutAtEnd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Radius radius = Radius.circular(AppRadii.field);
    final TextStyle style = AppTypography.caption.copyWith(
      height: 16 / 12,
      color: AppColors.text,
    );
    return Semantics(
      button: onTap != null,
      label: block.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _colorOf(block),
            // A conflicting stay is outlined so it stands out.
            border: block.conflictId == null
                ? null
                : Border.all(color: AppColors.error),
            borderRadius: BorderRadius.horizontal(
              left: isCutAtStart ? Radius.zero : radius,
              right: isCutAtEnd ? Radius.zero : radius,
            ),
          ),
          child: ClipRect(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.small,
                vertical: 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    block.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                  Text(
                    block.subtitle,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Airbnb pink, Booking.com green, direct orange, closed dates blue.
  static Color _colorOf(OccupancyBlockEntity block) {
    if (block.kind == OccupancyBlockKind.maintenance) {
      return AppColors.infoSurface;
    }
    return switch (block.source) {
      // The design's #FCE7EE has no token; it is the accent at 10 %.
      BookingSource.airbnb => Color.alphaBlend(
        AppColors.accent.withValues(alpha: 0.1),
        AppColors.background,
      ),
      BookingSource.bookingCom => AppColors.successSurface,
      BookingSource.direct || null => AppColors.warningSurface,
    };
  }
}
