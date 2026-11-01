import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/home/domain/entity/calendar_sync_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_task_entity.dart';

/// The groups of stays the home screen filters by.
enum HomeStayScope { arrivals, departures, staying }

/// Everything the home screen shows for one [date].
final class HomeOverviewEntity extends Equatable {
  const HomeOverviewEntity({
    required this.date,
    required this.arrivals,
    required this.departures,
    required this.staying,
    required this.tasks,
    required this.sync,
  });

  final DateTime date;

  final List<HomeStayEntity> arrivals;
  final List<HomeStayEntity> departures;
  final List<HomeStayEntity> staying;

  final List<HomeTaskEntity> tasks;
  final CalendarSyncEntity sync;

  List<HomeStayEntity> staysFor(HomeStayScope scope) {
    return switch (scope) {
      HomeStayScope.arrivals => arrivals,
      HomeStayScope.departures => departures,
      HomeStayScope.staying => staying,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    date,
    arrivals,
    departures,
    staying,
    tasks,
    sync,
  ];
}
