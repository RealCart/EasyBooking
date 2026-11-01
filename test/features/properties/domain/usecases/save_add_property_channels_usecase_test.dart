import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_channels_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

void main() {
  group('SaveAddPropertyChannelsUsecase', () {
    late FakePropertyManagementRepository repository;
    late SaveAddPropertyChannelsUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = SaveAddPropertyChannelsUsecase(repository);
    });

    test('keeps a repeated channel once, in first order', () async {
      final Either<Failure, void> result = await usecase(
        const SaveAddPropertyChannelsParamsEntity(
          channels: <BookingChannel>[
            BookingChannel.krisha,
            BookingChannel.airbnb,
            BookingChannel.krisha,
            BookingChannel.airbnb,
          ],
        ),
      );

      expect(result.isRight, isTrue);
      expect(repository.savedChannels.single, const <BookingChannel>[
        BookingChannel.krisha,
        BookingChannel.airbnb,
      ]);
    });

    test('an empty choice is saved', () async {
      await usecase(
        const SaveAddPropertyChannelsParamsEntity(channels: <BookingChannel>[]),
      );

      expect(repository.savedChannels.single, isEmpty);
    });

    test('the saved list cannot be changed', () async {
      await usecase(
        const SaveAddPropertyChannelsParamsEntity(
          channels: <BookingChannel>[BookingChannel.airbnb],
        ),
      );

      expect(
        () => repository.savedChannels.single.add(BookingChannel.krisha),
        throwsUnsupportedError,
      );
    });

    test('passes a repository failure through unchanged', () async {
      repository.saveChannelsResult = const Left<Failure, void>(
        StorageFailure(),
      );

      expect(
        await usecase(
          const SaveAddPropertyChannelsParamsEntity(
            channels: <BookingChannel>[BookingChannel.airbnb],
          ),
        ),
        const Left<Failure, void>(StorageFailure()),
      );
    });
  });
}
