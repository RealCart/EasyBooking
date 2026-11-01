import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';

import '../../../../helpers/fake_channels_repository.dart';

void main() {
  group('GetChannelUsecase', () {
    test('forwards the channel id and returns the channel', () async {
      final FakeChannelsRepository repository = FakeChannelsRepository();

      final Either<Failure, ChannelEntity> result = await GetChannelUsecase(
        repository,
      )(const GetChannelParamsEntity(channelId: 'airbnb'));

      expect(repository.channelRequests, <String>['airbnb']);
      expect(result, Right<Failure, ChannelEntity>(testAirbnbChannel()));
    });

    test('an unknown channel passes the 404 through', () async {
      final FakeChannelsRepository repository = FakeChannelsRepository();

      expect(
        await GetChannelUsecase(
          repository,
        )(const GetChannelParamsEntity(channelId: 'missing')),
        const Left<Failure, ChannelEntity>(ServerFailure(statusCode: 404)),
      );
    });
  });
}
