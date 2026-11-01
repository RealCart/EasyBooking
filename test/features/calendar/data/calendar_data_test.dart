import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/repository/calendar_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';
import 'package:easy_booking/features/properties/data/repository/properties_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

import '../../../helpers/fake_properties_repository.dart';

final DateTime _now = DateTime(2026, 10, 22, 9, 41);

CalendarDayEntity _valueOf(Either<Failure, CalendarDayEntity> result) {
  return result.fold(
    (Failure failure) => fail('Unexpected failure $failure'),
    (CalendarDayEntity day) => day,
  );
}

List<String> _guests(CalendarDayEntity day) {
  return <String>[
    for (final CalendarEventEntity event in day.events) event.guestName,
  ];
}

void main() {
  group('CalendarMockLocalImpl', () {
    const CalendarMockLocalImpl local = CalendarMockLocalImpl(now: _clock);

    test('no date loads today, ordered by time, as in the design', () async {
      final CalendarDayEntity day = _valueOf(await local.loadDay(null));

      expect(day.date, DateTime(2026, 10, 22));
      expect(day.today, DateTime(2026, 10, 22));
      expect(_guests(day), <String>['Арман', 'Айжан', 'Данияр']);
      expect(day.events.first.kind, CalendarEventKind.checkOut);
    });

    test('another day has its own events, ignoring the time', () async {
      final CalendarDayEntity sunday = _valueOf(
        await local.loadDay(DateTime(2026, 10, 25, 17)),
      );
      final CalendarDayEntity wednesday = _valueOf(
        await local.loadDay(DateTime(2026, 10, 21)),
      );

      expect(sunday.date, DateTime(2026, 10, 25));
      expect(_guests(sunday), <String>['Айжан', 'Тимур']);
      expect(wednesday.events, isEmpty);
    });
  });

  group('CalendarRepositoryImpl', () {
    late PropertiesMockLocalImpl properties;
    late CalendarRepositoryImpl repository;

    setUp(() {
      properties = PropertiesMockLocalImpl(now: _clock);
      repository = CalendarRepositoryImpl(
        local: const CalendarMockLocalImpl(now: _clock),
        properties: PropertiesRepositoryImpl(local: properties),
      );
    });

    test('all properties keep every event', () async {
      final CalendarDayEntity day = _valueOf(
        await repository.getDay(favoritesOnly: false),
      );

      expect(_guests(day), <String>['Арман', 'Айжан', 'Данияр']);
    });

    test('favorites keep only events of favorite properties', () async {
      final CalendarDayEntity day = _valueOf(
        await repository.getDay(favoritesOnly: true),
      );

      expect(_guests(day), <String>['Арман', 'Айжан']);
    });

    test('a heart changed in properties changes the favorites day', () async {
      await properties.setFavorite(
        propertyId: PropertiesMockLocalImpl.megaTowersId,
        isFavorite: false,
      );

      final CalendarDayEntity day = _valueOf(
        await repository.getDay(favoritesOnly: true),
      );

      expect(_guests(day), <String>['Айжан']);
    });

    test('a properties failure passes through for favorites only', () async {
      const Failure failure = ConnectionFailure();
      final CalendarRepositoryImpl failing = CalendarRepositoryImpl(
        local: const CalendarMockLocalImpl(now: _clock),
        properties: FakePropertiesRepository()
          ..propertiesResult = const Left<Failure, List<PropertyEntity>>(
            failure,
          ),
      );

      expect(
        await failing.getDay(favoritesOnly: true),
        const Left<Failure, CalendarDayEntity>(failure),
      );
      expect((await failing.getDay(favoritesOnly: false)).isRight, isTrue);
    });
  });
}

DateTime _clock() => _now;
