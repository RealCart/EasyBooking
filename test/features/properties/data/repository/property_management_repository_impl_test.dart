import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/data/repository/property_management_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';

import '../../../../helpers/fake_properties_repository.dart';
import '../../../../helpers/fake_property_management_repository.dart';

const Failure _failure = StorageFailure(message: 'disk');

const SaveAddPropertyDetailsParamsEntity _details =
    SaveAddPropertyDetailsParamsEntity(
      title: 'Al-Farabi Residence · 19',
      address: 'Аль-Фараби, 21',
      type: PropertyType.room,
      rooms: 1,
    );

/// Records every call and answers with the `*Result` fields.
final class _FakeManagementMockLocal implements PropertyManagementMockLocal {
  Either<Failure, PropertyBookingsEntity> bookingsResult =
      Right<Failure, PropertyBookingsEntity>(testPropertyBookings());
  Either<Failure, PropertySettingsEntity> settingsResult =
      Right<Failure, PropertySettingsEntity>(testPropertySettings());
  Either<Failure, AddPropertyDraftEntity> draftResult =
      const Right<Failure, AddPropertyDraftEntity>(testFilledDraft);
  Either<Failure, void> writeResult = const Right<Failure, void>(null);
  Either<Failure, String> publishResult = const Right<Failure, String>('new');

  final List<String> calls = <String>[];
  final List<Object?> arguments = <Object?>[];

  @override
  Future<Either<Failure, List<PropertyEntity>>> loadProperties() async {
    calls.add('loadProperties');
    return Right<Failure, List<PropertyEntity>>(testProperties());
  }

  @override
  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  }) async {
    calls.add('setFavorite');
    return writeResult;
  }

  @override
  Future<Either<Failure, PropertyBookingsEntity>> loadBookings(
    String propertyId,
  ) async {
    calls.add('loadBookings');
    arguments.add(propertyId);
    return bookingsResult;
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> loadSettings(
    String propertyId,
  ) async {
    calls.add('loadSettings');
    arguments.add(propertyId);
    return settingsResult;
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  }) async {
    calls.add('saveSettings');
    arguments.add((propertyId: propertyId, acceptsBookings: acceptsBookings));
    return settingsResult;
  }

  @override
  Future<Either<Failure, AddPropertyDraftEntity>> loadDraft() async {
    calls.add('loadDraft');
    return draftResult;
  }

  @override
  Future<Either<Failure, void>> saveDraftDetails(
    SaveAddPropertyDetailsParamsEntity details,
  ) async {
    calls.add('saveDraftDetails');
    arguments.add(details);
    return writeResult;
  }

  @override
  Future<Either<Failure, void>> saveDraftChannels(
    List<BookingChannel> channels,
  ) async {
    calls.add('saveDraftChannels');
    arguments.add(channels);
    return writeResult;
  }

  @override
  Future<Either<Failure, String>> publishDraft(
    PropertyTermsEntity terms,
  ) async {
    calls.add('publishDraft');
    arguments.add(terms);
    return publishResult;
  }
}

void main() {
  group('PropertyManagementRepositoryImpl', () {
    late _FakeManagementMockLocal local;
    late PropertyManagementRepositoryImpl repository;

    setUp(() {
      local = _FakeManagementMockLocal();
      repository = PropertyManagementRepositoryImpl(local: local);
    });

    test('getBookings forwards the id and returns the bookings', () async {
      final Either<Failure, PropertyBookingsEntity> result = await repository
          .getBookings('p1');

      expect(local.calls, <String>['loadBookings']);
      expect(local.arguments, <Object?>['p1']);
      expect(
        result,
        Right<Failure, PropertyBookingsEntity>(testPropertyBookings()),
      );
    });

    test('getSettings forwards the id and returns the settings', () async {
      final Either<Failure, PropertySettingsEntity> result = await repository
          .getSettings('p1');

      expect(local.calls, <String>['loadSettings']);
      expect(local.arguments, <Object?>['p1']);
      expect(
        result,
        Right<Failure, PropertySettingsEntity>(testPropertySettings()),
      );
    });

    test('saveSettings forwards both values', () async {
      await repository.saveSettings(propertyId: 'p2', acceptsBookings: false);

      expect(local.calls, <String>['saveSettings']);
      expect(local.arguments.single, (
        propertyId: 'p2',
        acceptsBookings: false,
      ));
    });

    test('getAddPropertyDraft returns the stored draft', () async {
      expect(
        await repository.getAddPropertyDraft(),
        const Right<Failure, AddPropertyDraftEntity>(testFilledDraft),
      );
      expect(local.calls, <String>['loadDraft']);
    });

    test('saveAddPropertyDetails forwards the details', () async {
      final Either<Failure, void> result = await repository
          .saveAddPropertyDetails(_details);

      expect(result.isRight, isTrue);
      expect(local.calls, <String>['saveDraftDetails']);
      expect(local.arguments.single, _details);
    });

    test('saveAddPropertyChannels forwards the channels', () async {
      await repository.saveAddPropertyChannels(const <BookingChannel>[
        BookingChannel.krisha,
        BookingChannel.airbnb,
      ]);

      expect(local.calls, <String>['saveDraftChannels']);
      expect(local.arguments.single, const <BookingChannel>[
        BookingChannel.krisha,
        BookingChannel.airbnb,
      ]);
    });

    test('publishProperty forwards the terms and returns the id', () async {
      final Either<Failure, String> result = await repository.publishProperty(
        testTerms,
      );

      expect(local.calls, <String>['publishDraft']);
      expect(local.arguments.single, testTerms);
      expect(result, const Right<Failure, String>('new'));
    });

    test('every failure of the source passes through unchanged', () async {
      local
        ..bookingsResult = const Left<Failure, PropertyBookingsEntity>(
          _failure,
        )
        ..settingsResult = const Left<Failure, PropertySettingsEntity>(
          _failure,
        )
        ..draftResult = const Left<Failure, AddPropertyDraftEntity>(_failure)
        ..writeResult = const Left<Failure, void>(_failure)
        ..publishResult = const Left<Failure, String>(
          ValidationFailure(code: 'draft_incomplete'),
        );

      expect(
        await repository.getBookings('p1'),
        const Left<Failure, PropertyBookingsEntity>(_failure),
      );
      expect(
        await repository.getSettings('p1'),
        const Left<Failure, PropertySettingsEntity>(_failure),
      );
      expect(
        await repository.saveSettings(propertyId: 'p1', acceptsBookings: true),
        const Left<Failure, PropertySettingsEntity>(_failure),
      );
      expect(
        await repository.getAddPropertyDraft(),
        const Left<Failure, AddPropertyDraftEntity>(_failure),
      );
      expect(
        await repository.saveAddPropertyDetails(_details),
        const Left<Failure, void>(_failure),
      );
      expect(
        await repository.saveAddPropertyChannels(const <BookingChannel>[]),
        const Left<Failure, void>(_failure),
      );
      expect(
        await repository.publishProperty(testTerms),
        const Left<Failure, String>(
          ValidationFailure(code: 'draft_incomplete'),
        ),
      );
    });
  });
}
