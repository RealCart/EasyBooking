import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_labels.dart';

extension OccupancyRowLabels on OccupancyRowEntity {
  /// `Esentai · 84`: the first word of the building keeps the column narrow.
  String get shortTitle {
    final String building = propertyName.trim().split(' ').first;
    return '$building · $unit';
  }

  /// `42 500 ₸`
  String get priceLabel => MoneyFormatter.tenge(pricePerNight);
}

extension OccupancyBlockLabels on OccupancyBlockEntity {
  /// `Айжан · Airbnb` for a stay, `Ремонт` for closed dates.
  String get title {
    return switch (kind) {
      OccupancyBlockKind.maintenance => 'Ремонт',
      OccupancyBlockKind.booking => <String>[
        ?guestName,
        ?source?.shortTitle,
      ].join(' · '),
    };
  }

  /// `3 ночи` for a stay, `до 31 окт` for closed dates.
  String get subtitle {
    return switch (kind) {
      OccupancyBlockKind.maintenance =>
        'до ${DateFormatter.dayMonth(lastDay, short: true)}',
      OccupancyBlockKind.booking => CalendarLabels.nights(nights),
    };
  }

  /// Read by screen readers instead of the two short lines.
  String get semanticLabel {
    final String dates = DateFormatter.dayRange(start, lastDay);
    final String conflict = conflictId == null ? '' : ', конфликт календарей';
    return '$title, $subtitle, $dates$conflict';
  }
}

extension OccupancyWeekLabels on OccupancyWeekEntity {
  String get syncTitle {
    return isSyncHealthy ? 'Все каналы обновлены' : 'Не все каналы обновились';
  }

  /// `Последняя проверка в 09:38`
  String get syncSubtitle {
    return 'Последняя проверка '
        '${CalendarLabels.dayAtTime(syncCheckedAt, now: today)}';
  }
}
