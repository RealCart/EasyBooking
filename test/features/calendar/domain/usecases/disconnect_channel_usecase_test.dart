import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/disconnect_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';

import '../../../../helpers/fake_channels_repository.dart';

void main() {
  group('DisconnectChannelUsecase', () {
    test('forwards the channel id and succeeds', () async {
      final FakeChannelsRepository repository = FakeChannelsRepository();

      final Either<Failure, void> result = await DisconnectChannelUsecase(
        repository,
      )(const DisconnectChannelParamsEntity(channelId: 'airbnb'));

      expect(repository.disconnectRequests, <String>['airbnb']);
      expect(result.isRight, isTrue);
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = TimeoutFailure();
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..disconnectResult = const Left<Failure, void>(failure);

      expect(
        await DisconnectChannelUsecase(
          repository,
        )(const DisconnectChannelParamsEntity(channelId: 'airbnb')),
        const Left<Failure, void>(failure),
      );
    });
  });
}
