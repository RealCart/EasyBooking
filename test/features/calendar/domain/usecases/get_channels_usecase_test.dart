import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';

import '../../../../helpers/fake_channels_repository.dart';

void main() {
  group('GetChannelsUsecase', () {
    test('returns the channels overview', () async {
      final FakeChannelsRepository repository = FakeChannelsRepository();

      final Either<Failure, ChannelsOverviewEntity> result =
          await GetChannelsUsecase(repository)(const NoParams());

      expect(repository.channelsCount, 1);
      expect(
        result,
        Right<Failure, ChannelsOverviewEntity>(testChannelsOverview()),
      );
    });

    test('a failure passes through unchanged', () async {
      const Failure failure = ConnectionFailure();
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..channelsResult = const Left<Failure, ChannelsOverviewEntity>(
          failure,
        );

      expect(
        await GetChannelsUsecase(repository)(const NoParams()),
        const Left<Failure, ChannelsOverviewEntity>(failure),
      );
    });
  });
}
