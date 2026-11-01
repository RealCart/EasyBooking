import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/repository/calendar_conflicts_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/repository/channels_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/repository/occupancy_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_schedule_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/properties/data/repository/properties_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

import '../../../../helpers/fake_calendar_sync_mock_local.dart';
import '../../../../helpers/fake_properties_repository.dart';

OccupancyWeekEntity _valueOf(Either<Failure, OccupancyWeekEntity> result) {
  return result.fold(
    (Failure failure) => fail('Unexpected failure $failure'),
    (OccupancyWeekEntity week) => week,
  );
}

List<String> _rowIds(OccupancyWeekEntity week) {
  return <String>[
    for (final OccupancyRowEntity row in week.rows) row.propertyId,
  ];
}

List<String> _blockIds(OccupancyRowEntity row) {
  return <String>[
    for (final OccupancyBlockEntity block in row.blocks) block.id,
  ];
}

DateTime _clock() => DateTime(2026, 10, 22, 9, 41);

void main() {
  group('OccupancyRepositoryImpl', () {
    late FakeCalendarSyncMockLocal local;
    late FakePropertiesRepository properties;
    late OccupancyRepositoryImpl repository;

    setUp(() {
      local = FakeCalendarSyncMockLocal();
      properties = FakePropertiesRepository();
      repository = OccupancyRepositoryImpl(
        local: local,
        properties: properties,
      );
    });

    test('forwards the date and keeps the schedule\'s week fields', () async {
      final DateTime date = DateTime(2026, 10, 21);

      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false, date: date),
      );

      expect(local.scheduleRequests, <DateTime?>[date]);
      expect(week.weekStart, DateTime(2026, 10, 19));
      expect(week.today, DateTime(2026, 10, 22));
      expect(week.syncCheckedAt, DateTime(2026, 10, 22, 9, 38));
      expect(week.isSyncHealthy, isFalse);
    });

    test(
      'rows follow the properties order with their names and prices',
      () async {
        properties.propertiesResult = Right<Failure, List<PropertyEntity>>(
          testProperties().reversed.toList(),
        );

        final OccupancyWeekEntity week = _valueOf(
          await repository.getWeek(favoritesOnly: false),
        );

        expect(_rowIds(week), <String>['p2', 'p1']);
        final OccupancyRowEntity megaTowers = week.rows.first;
        expect(megaTowers.propertyName, 'Mega Towers');
        expect(megaTowers.unit, '126');
        expect(megaTowers.pricePerNight, 32000);
        expect(_blockIds(megaTowers), <String>['s2']);
        expect(_blockIds(week.rows.last), <String>['s1', 's4']);
      },
    );

    test('blocks of unknown properties are dropped', () async {
      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false),
      );

      expect(
        week.rows.expand((OccupancyRowEntity row) => row.blocks),
        everyElement(
          isA<OccupancyBlockEntity>().having(
            (OccupancyBlockEntity block) => block.propertyId,
            'propertyId',
            isNot('p9'),
          ),
        ),
      );
    });

    test('a property without bookings still gets an empty row', () async {
      local.scheduleResult = Right<Failure, OccupancyScheduleEntity>(
        OccupancyScheduleEntity(
          weekStart: DateTime(2026, 10, 26),
          today: DateTime(2026, 10, 22),
          blocks: const <OccupancyBlockEntity>[],
          syncCheckedAt: DateTime(2026, 10, 22, 9, 38),
          isSyncHealthy: true,
        ),
      );

      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false),
      );

      expect(_rowIds(week), <String>['p1', 'p2']);
      expect(
        week.rows.every((OccupancyRowEntity row) => row.blocks.isEmpty),
        isTrue,
      );
    });

    test('favorites keep only rows of favorite properties', () async {
      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: true),
      );

      expect(_rowIds(week), <String>['p1']);
    });

    test('published rows and blocks cannot be changed', () async {
      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false),
      );

      expect(() => week.rows.removeLast(), throwsUnsupportedError);
      expect(() => week.rows.first.blocks.clear(), throwsUnsupportedError);
    });

    test('a schedule failure passes through and skips properties', () async {
      const Failure failure = StorageFailure(message: 'read failed');
      local.scheduleResult = const Left<Failure, OccupancyScheduleEntity>(
        failure,
      );

      expect(
        await repository.getWeek(favoritesOnly: true),
        const Left<Failure, OccupancyWeekEntity>(failure),
      );
      expect(properties.propertiesCount, 0);
    });

    test('a properties failure passes through unchanged', () async {
      const Failure failure = ServerFailure(statusCode: 503, code: 'down');
      properties.propertiesResult = const Left<Failure, List<PropertyEntity>>(
        failure,
      );

      expect(
        await repository.getWeek(favoritesOnly: false),
        const Left<Failure, OccupancyWeekEntity>(failure),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(
        repository.getWeek(favoritesOnly: false),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OccupancyRepositoryImpl over the real mocks', () {
    late CalendarSyncMockLocalImpl local;
    late OccupancyRepositoryImpl repository;

    setUp(() {
      local = CalendarSyncMockLocalImpl(now: _clock);
      repository = OccupancyRepositoryImpl(
        local: local,
        properties: PropertiesRepositoryImpl(
          local: PropertiesMockLocalImpl(now: _clock),
        ),
      );
    });

    test('every property gets a row, Highvill with no stays', () async {
      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false),
      );

      expect(_rowIds(week), <String>[
        PropertiesMockLocalImpl.esentaiId,
        PropertiesMockLocalImpl.megaTowersId,
        PropertiesMockLocalImpl.samalId,
        PropertiesMockLocalImpl.highvillId,
      ]);
      expect(_blockIds(week.rows[0]), <String>['stay-1042', 'stay-1046']);
      expect(week.rows[0].propertyName, 'Esentai City');
      expect(week.rows[0].pricePerNight, 42500);
      expect(week.rows[3].blocks, isEmpty);
      expect(week.isSyncHealthy, isFalse);
    });

    test('favorites show Esentai and Mega Towers', () async {
      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: true),
      );

      expect(_rowIds(week), <String>[
        PropertiesMockLocalImpl.esentaiId,
        PropertiesMockLocalImpl.megaTowersId,
      ]);
    });

    test('a resolved conflict and a synced Airbnb show on occupancy', () async {
      await CalendarConflictsRepositoryImpl(local: local).resolveConflict(
        conflictId: CalendarSyncMockLocalImpl.esentaiConflictId,
        keepBookingId: 'booking-1042',
      );
      await ChannelsRepositoryImpl(
        local: local,
      ).syncChannel(CalendarSyncMockLocalImpl.airbnbId);

      final OccupancyWeekEntity week = _valueOf(
        await repository.getWeek(favoritesOnly: false),
      );

      expect(_blockIds(week.rows[0]), <String>['stay-1042']);
      expect(week.rows[0].blocks.single.conflictId, isNull);
      expect(week.isSyncHealthy, isTrue);
      expect(week.syncCheckedAt, _clock());
    });
  });
}
