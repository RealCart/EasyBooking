import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/sync_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';

import '../../../../helpers/fake_channels_repository.dart';

void main() {
  group('SyncChannelUsecase', () {
    test('forwards the channel id and returns the synced channel', () async {
      final FakeChannelsRepository repository = FakeChannelsRepository();

      final Either<Failure, ChannelEntity> result = await SyncChannelUsecase(
        repository,
      )(const SyncChannelParamsEntity(channelId: 'airbnb'));

      expect(repository.syncRequests, <String>['airbnb']);
      expect(
        result,
        Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true)),
      );
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = ServerFailure(statusCode: 409);
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..syncResult = const Left<Failure, ChannelEntity>(failure);

      expect(
        await SyncChannelUsecase(
          repository,
        )(const SyncChannelParamsEntity(channelId: 'avito')),
        const Left<Failure, ChannelEntity>(failure),
      );
    });
  });
}
