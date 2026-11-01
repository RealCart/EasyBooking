import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/repository/channels_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';

import '../../../../helpers/fake_calendar_sync_mock_local.dart';
import '../../../../helpers/fake_channels_repository.dart';

void main() {
  group('ChannelsRepositoryImpl', () {
    late FakeCalendarSyncMockLocal local;
    late ChannelsRepositoryImpl repository;

    setUp(() {
      local = FakeCalendarSyncMockLocal();
      repository = ChannelsRepositoryImpl(local: local);
    });

    test('getChannels returns the overview of the source', () async {
      expect(
        await repository.getChannels(),
        Right<Failure, ChannelsOverviewEntity>(testChannelsOverview()),
      );
      expect(local.channelsCount, 1);
    });

    test('getChannels passes a failure through', () async {
      const Failure failure = StorageFailure();
      local.channelsResult = const Left<Failure, ChannelsOverviewEntity>(
        failure,
      );

      expect(
        await repository.getChannels(),
        const Left<Failure, ChannelsOverviewEntity>(failure),
      );
    });

    test('getChannel picks the channel from the overview', () async {
      expect(
        await repository.getChannel('airbnb'),
        Right<Failure, ChannelEntity>(testAirbnbChannel()),
      );
    });

    test('getChannel of an unknown id is a 404', () async {
      final Either<Failure, ChannelEntity> result = await repository.getChannel(
        'missing',
      );

      expect(
        result.fold((Failure f) => (f as ServerFailure).statusCode, (_) => 0),
        404,
      );
    });

    test('getChannel passes a load failure through', () async {
      const Failure failure = ConnectionFailure();
      local.channelsResult = const Left<Failure, ChannelsOverviewEntity>(
        failure,
      );

      expect(
        await repository.getChannel('airbnb'),
        const Left<Failure, ChannelEntity>(failure),
      );
    });

    test(
      'syncChannel forwards the id and returns the synced channel',
      () async {
        expect(
          await repository.syncChannel('airbnb'),
          Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true)),
        );
        expect(local.syncRequests, <String>['airbnb']);
      },
    );

    test('syncChannel passes a failure through', () async {
      const Failure failure = ServerFailure(statusCode: 409);
      local.syncResult = const Left<Failure, ChannelEntity>(failure);

      expect(
        await repository.syncChannel('avito'),
        const Left<Failure, ChannelEntity>(failure),
      );
    });

    test('disconnectChannel forwards the id and passes the result', () async {
      expect((await repository.disconnectChannel('airbnb')).isRight, isTrue);
      expect(local.disconnectRequests, <String>['airbnb']);

      const Failure failure = ServerFailure(statusCode: 404);
      local.disconnectResult = const Left<Failure, void>(failure);
      expect(
        await repository.disconnectChannel('missing'),
        const Left<Failure, void>(failure),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getChannel('airbnb'), throwsStateError);
      await expectLater(repository.syncChannel('airbnb'), throwsStateError);
    });
  });

  group('ChannelsRepositoryImpl over the real mock', () {
    test('a disconnect lasts for later reads of the channel', () async {
      final ChannelsRepositoryImpl repository = ChannelsRepositoryImpl(
        local: CalendarSyncMockLocalImpl(
          now: () => DateTime(2026, 10, 22, 9, 41),
        ),
      );

      await repository.disconnectChannel(CalendarSyncMockLocalImpl.krishaId);
      final Either<Failure, ChannelEntity> krisha = await repository.getChannel(
        CalendarSyncMockLocalImpl.krishaId,
      );

      expect(
        krisha.fold((_) => null, (ChannelEntity c) => c.status),
        ChannelStatus.disconnected,
      );
    });
  });
}
