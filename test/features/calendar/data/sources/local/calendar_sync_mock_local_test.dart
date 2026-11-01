import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_schedule_entity.dart';

const String _airbnb = CalendarSyncMockLocalImpl.airbnbId;
const String _bookingCom = CalendarSyncMockLocalImpl.bookingComId;
const String _krisha = CalendarSyncMockLocalImpl.krishaId;
const String _conflictId = CalendarSyncMockLocalImpl.esentaiConflictId;

T _valueOf<T>(Either<Failure, T> result) {
  return result.fold(
    (Failure failure) => fail('Unexpected failure $failure'),
    (T value) => value,
  );
}

List<String> _blockIds(OccupancyScheduleEntity schedule) {
  return <String>[
    for (final OccupancyBlockEntity block in schedule.blocks) block.id,
  ];
}

ChannelEntity _channel(ChannelsOverviewEntity overview, String id) {
  return overview.channels.singleWhere((ChannelEntity c) => c.id == id);
}

void main() {
  group('CalendarSyncMockLocalImpl', () {
    // Thursday, 22 October 2026, 09:41.
    late DateTime now;
    late CalendarSyncMockLocalImpl local;

    setUp(() {
      now = DateTime(2026, 10, 22, 9, 41);
      local = CalendarSyncMockLocalImpl(now: () => now);
    });

    group('loadSchedule', () {
      test('no date loads the current week, ordered by start', () async {
        final OccupancyScheduleEntity schedule = _valueOf(
          await local.loadSchedule(null),
        );

        expect(schedule.weekStart, DateTime(2026, 10, 19));
        expect(schedule.today, DateTime(2026, 10, 22));
        expect(_blockIds(schedule), <String>[
          'stay-1039',
          'stay-1042',
          'stay-1044',
          'stay-1046',
          'maintenance-samal-12',
          'stay-1051',
        ]);
        expect(schedule.syncCheckedAt, DateTime(2026, 10, 22, 9, 38));
        expect(schedule.isSyncHealthy, isFalse);
        expect(
          () => schedule.blocks.add(schedule.blocks.first),
          throwsUnsupportedError,
        );
      });

      test('the two Esentai stays carry the conflict id', () async {
        final OccupancyScheduleEntity schedule = _valueOf(
          await local.loadSchedule(null),
        );

        final Map<String, String?> conflictByBlock = <String, String?>{
          for (final OccupancyBlockEntity block in schedule.blocks)
            block.id: block.conflictId,
        };
        expect(conflictByBlock['stay-1042'], _conflictId);
        expect(conflictByBlock['stay-1046'], _conflictId);
        expect(conflictByBlock['stay-1044'], isNull);
        final OccupancyBlockEntity maintenance = schedule.blocks.singleWhere(
          (OccupancyBlockEntity block) =>
              block.kind == OccupancyBlockKind.maintenance,
        );
        expect(maintenance.bookingId, isNull);
      });

      test('any day of another week loads that week from Monday', () async {
        final OccupancyScheduleEntity next = _valueOf(
          await local.loadSchedule(DateTime(2026, 10, 28, 15)),
        );
        final OccupancyScheduleEntity previous = _valueOf(
          await local.loadSchedule(DateTime(2026, 10, 18)),
        );

        expect(next.weekStart, DateTime(2026, 10, 26));
        expect(_blockIds(next), <String>[
          'stay-1046',
          'maintenance-samal-12',
          'stay-1051',
        ]);
        expect(previous.weekStart, DateTime(2026, 10, 12));
        expect(previous.blocks, isEmpty);
      });
    });

    group('loadChannels', () {
      test(
        'lists Booking.com, the failing Airbnb, and manual Krisha',
        () async {
          final ChannelsOverviewEntity overview = _valueOf(
            await local.loadChannels(),
          );

          expect(
            <String>[for (final ChannelEntity c in overview.channels) c.id],
            <String>[_bookingCom, _airbnb, _krisha],
          );
          expect(
            _channel(overview, _bookingCom).status,
            ChannelStatus.connected,
          );
          final ChannelEntity airbnb = _channel(overview, _airbnb);
          expect(airbnb.status, ChannelStatus.failed);
          expect(
            <String>[
              for (final ChannelConnectionEntity connection
                  in airbnb.failedConnections)
                connection.propertyId,
            ],
            <String>['esentai-city-84'],
          );
          final ChannelEntity krisha = _channel(overview, _krisha);
          expect(krisha.status, ChannelStatus.manual);
          expect(krisha.connections, isEmpty);
          expect(krisha.lastSyncedAt, isNull);
          expect(krisha.nextCheckAt, isNull);
          expect(overview.checkedAt, DateTime(2026, 10, 22, 9, 38));
          expect(airbnb.lastSyncedAt, DateTime(2026, 10, 22, 9, 38));
          expect(airbnb.nextCheckAt, DateTime(2026, 10, 22, 9, 53));
        },
      );
    });

    group('syncChannel', () {
      test('syncing Airbnb repairs Esentai, everywhere', () async {
        final ChannelEntity synced = _valueOf(await local.syncChannel(_airbnb));

        expect(synced.status, ChannelStatus.connected);
        expect(synced.failedConnections, isEmpty);
        expect(synced.lastSyncedAt, now);

        now = DateTime(2026, 10, 22, 9, 50);
        final ChannelsOverviewEntity overview = _valueOf(
          await local.loadChannels(),
        );
        final ChannelEntity airbnb = _channel(overview, _airbnb);
        expect(airbnb.status, ChannelStatus.connected);
        expect(airbnb.lastSyncedAt, DateTime(2026, 10, 22, 9, 41));
        expect(airbnb.nextCheckAt, DateTime(2026, 10, 22, 9, 56));
        expect(
          _valueOf(await local.loadSchedule(null)).isSyncHealthy,
          isTrue,
        );
      });

      test('syncing Booking.com leaves Airbnb failing', () async {
        _valueOf(await local.syncChannel(_bookingCom));

        final ChannelsOverviewEntity overview = _valueOf(
          await local.loadChannels(),
        );
        expect(_channel(overview, _airbnb).status, ChannelStatus.failed);
        expect(overview.checkedAt, now);
        expect(
          _valueOf(await local.loadSchedule(null)).isSyncHealthy,
          isFalse,
        );
      });

      test('an unknown channel is a 404', () async {
        final Either<Failure, ChannelEntity> result = await local.syncChannel(
          'avito',
        );

        expect(
          result,
          const Left<Failure, ChannelEntity>(
            ServerFailure(statusCode: 404, message: 'Unknown channel avito'),
          ),
        );
      });

      test('a disconnected channel is a 409', () async {
        _valueOf(await local.disconnectChannel(_bookingCom));

        final Either<Failure, ChannelEntity> result = await local.syncChannel(
          _bookingCom,
        );

        expect(result.isLeft, isTrue);
        expect(
          result.fold((Failure f) => (f as ServerFailure).statusCode, (_) => 0),
          409,
        );
      });
    });

    group('disconnectChannel', () {
      test('clears the connections and the sync times', () async {
        expect(
          await local.disconnectChannel(_airbnb),
          isA<Right<Failure, void>>(),
        );

        final ChannelsOverviewEntity overview = _valueOf(
          await local.loadChannels(),
        );
        final ChannelEntity airbnb = _channel(overview, _airbnb);
        expect(airbnb.status, ChannelStatus.disconnected);
        expect(airbnb.connections, isEmpty);
        expect(airbnb.lastSyncedAt, isNull);
        expect(airbnb.nextCheckAt, isNull);
        expect(overview.activeChannelCount, 2);
        // The only failing channel is gone.
        expect(
          _valueOf(await local.loadSchedule(null)).isSyncHealthy,
          isTrue,
        );
      });

      test('an unknown channel is a 404', () async {
        expect(
          await local.disconnectChannel('avito'),
          const Left<Failure, void>(
            ServerFailure(statusCode: 404, message: 'Unknown channel avito'),
          ),
        );
      });
    });

    group('conflicts', () {
      test('the Esentai conflict opposes booking-1042 and 1046', () async {
        final CalendarConflictEntity conflict = _valueOf(
          await local.loadConflict(_conflictId),
        );

        expect(
          <String>[
            for (final ConflictBookingEntity booking in conflict.bookings)
              booking.bookingId,
          ],
          <String>['booking-1042', 'booking-1046'],
        );
        expect(conflict.isResolved, isFalse);
        expect(conflict.overlapStart, DateTime(2026, 10, 24));
        expect(conflict.overlapEnd, DateTime(2026, 10, 25));
        expect((conflict.position, conflict.total), (1, 1));
      });

      test('an unknown conflict is a 404 to load and to resolve', () async {
        const Failure failure = ServerFailure(
          statusCode: 404,
          message: 'Unknown conflict c9',
        );

        expect(
          await local.loadConflict('c9'),
          const Left<Failure, CalendarConflictEntity>(failure),
        );
        expect(
          await local.resolveConflict(
            conflictId: 'c9',
            keepBookingId: 'booking-1042',
          ),
          const Left<Failure, CalendarConflictEntity>(failure),
        );
      });

      test(
        'resolving keeps one stay and removes the other from occupancy',
        () async {
          final CalendarConflictEntity resolved = _valueOf(
            await local.resolveConflict(
              conflictId: _conflictId,
              keepBookingId: 'booking-1046',
            ),
          );

          expect(resolved.keptBookingId, 'booking-1046');
          expect(
            _valueOf(await local.loadConflict(_conflictId)).keptBookingId,
            'booking-1046',
          );
          final OccupancyScheduleEntity schedule = _valueOf(
            await local.loadSchedule(null),
          );
          expect(_blockIds(schedule), isNot(contains('stay-1042')));
          final OccupancyBlockEntity kept = schedule.blocks.singleWhere(
            (OccupancyBlockEntity block) => block.id == 'stay-1046',
          );
          expect(kept.conflictId, isNull);
        },
      );

      test('a conflict resolves once: the second resolve is a 409', () async {
        _valueOf(
          await local.resolveConflict(
            conflictId: _conflictId,
            keepBookingId: 'booking-1042',
          ),
        );

        final Either<Failure, CalendarConflictEntity> second = await local
            .resolveConflict(
              conflictId: _conflictId,
              keepBookingId: 'booking-1046',
            );

        expect(
          second.fold((Failure f) => (f as ServerFailure).statusCode, (_) => 0),
          409,
        );
        expect(
          _valueOf(await local.loadConflict(_conflictId)).keptBookingId,
          'booking-1042',
        );
      });

      test(
        'a booking outside the conflict is a 404 and changes nothing',
        () async {
          final Either<Failure, CalendarConflictEntity> result = await local
              .resolveConflict(
                conflictId: _conflictId,
                keepBookingId: 'booking-1044',
              );

          expect(
            result.fold(
              (Failure f) => (f as ServerFailure).statusCode,
              (_) => 0,
            ),
            404,
          );
          expect(
            _valueOf(await local.loadConflict(_conflictId)).isResolved,
            isFalse,
          );
          expect(
            _blockIds(_valueOf(await local.loadSchedule(null))),
            containsAll(<String>['stay-1042', 'stay-1046']),
          );
        },
      );
    });
  });
}
