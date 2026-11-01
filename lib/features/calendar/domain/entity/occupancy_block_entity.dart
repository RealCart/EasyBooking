import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';

enum OccupancyBlockKind {
  /// A guest's stay; [OccupancyBlockEntity.bookingId],
  /// [OccupancyBlockEntity.guestName], and [OccupancyBlockEntity.source] are
  /// set.
  booking,

  /// The host closed the dates, for example for repairs («Ремонт»).
  maintenance,
}

/// A span of time when a property is not free.
final class OccupancyBlockEntity extends Equatable {
  const OccupancyBlockEntity({
    required this.id,
    required this.propertyId,
    required this.kind,
    required this.start,
    required this.end,
    this.bookingId,
    this.guestName,
    this.source,
    this.conflictId,
  });

  final String id;
  final String propertyId;
  final OccupancyBlockKind kind;

  /// Check-in time, or midnight of the first closed day.
  final DateTime start;

  /// Exclusive: check-out time, or midnight after the last closed day.
  final DateTime end;

  final String? bookingId;

  /// First name, as shown on the bar.
  final String? guestName;
  final BookingSource? source;

  /// Set while this booking overlaps another one; the id of that calendar
  /// conflict.
  final String? conflictId;

  int get nights => start.nightsUntil(end);

  /// The last day the block covers, at midnight («до 31 окт»).
  DateTime get lastDay {
    final DateTime endDay = end.dateOnly;
    return end == endDay ? endDay.addDays(-1) : endDay;
  }

  /// Whether the block covers any moment of [from] (inclusive) to [to]
  /// (exclusive).
  bool overlaps(DateTime from, DateTime to) {
    return start.isBefore(to) && end.isAfter(from);
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    propertyId,
    kind,
    start,
    end,
    bookingId,
    guestName,
    source,
    conflictId,
  ];
}
