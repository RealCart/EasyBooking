import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/data/repository/properties_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';

T _right<T>(Either<Failure, T> result) {
  return result.fold(
    (Failure failure) => fail('Unexpected failure $failure'),
    (T value) => value,
  );
}

Failure? _left<T>(Either<Failure, T> result) {
  return result.fold((Failure failure) => failure, (_) => null);
}

final Matcher _isNotFound = isA<ServerFailure>().having(
  (ServerFailure failure) => failure.statusCode,
  'statusCode',
  404,
);

const PropertyTermsEntity _terms = PropertyTermsEntity(
  pricePerNight: 30000,
  deposit: 0,
  checkInTime: Duration(hours: 15, minutes: 30),
  checkOutTime: Duration(hours: 11),
  minNights: 3,
  cleaningFee: 5000,
);

SaveAddPropertyDetailsParamsEntity _details(String title) {
  return SaveAddPropertyDetailsParamsEntity(
    title: title,
    address: 'Аль-Фараби, 21',
    type: PropertyType.house,
    rooms: 3,
  );
}

void main() {
  group('PropertiesMockLocalImpl', () {
    final DateTime now = DateTime(2026, 10, 22, 9, 41);
    late PropertiesMockLocalImpl local;

    setUp(() {
      local = PropertiesMockLocalImpl(now: () => now);
    });

    Future<List<PropertyEntity>> load() async {
      final Either<Failure, List<PropertyEntity>> result = await local
          .loadProperties();
      return result.fold(
        (Failure failure) => fail('Unexpected failure $failure'),
        (List<PropertyEntity> properties) => properties,
      );
    }

    test('two of four apartments are busy today, as in the design', () async {
      final List<PropertyEntity> properties = await load();

      expect(properties, hasLength(4));
      expect(
        properties.where((PropertyEntity p) => p.availability.isBusy),
        hasLength(2),
      );
      for (final PropertyEntity property in properties) {
        expect(property.imageUrls, isNotEmpty);
      }
    });

    test('ids match the ones Home links to', () async {
      final Set<String> ids = <String>{
        for (final PropertyEntity property in await load()) property.id,
      };

      expect(ids, containsAll(<String>['esentai-city-84', 'samal-residence']));
    });

    test('a favorite change lasts into later loads', () async {
      final Either<Failure, void> result = await local.setFavorite(
        propertyId: PropertiesMockLocalImpl.highvillId,
        isFavorite: true,
      );

      expect(result.isRight, isTrue);
      expect(
        (await load())
            .where((PropertyEntity property) => property.isFavorite)
            .map((PropertyEntity property) => property.id),
        containsAll(<String>[PropertiesMockLocalImpl.highvillId]),
      );
    });

    test('an unknown property cannot be favorited', () async {
      final Either<Failure, void> result = await local.setFavorite(
        propertyId: 'missing',
        isFavorite: true,
      );

      expect(
        result.fold((Failure failure) => failure, (_) => null),
        isA<ServerFailure>().having(
          (ServerFailure failure) => failure.statusCode,
          'statusCode',
          404,
        ),
      );
    });
  });

  group('PropertiesMockLocalImpl bookings', () {
    late DateTime now;
    late PropertiesMockLocalImpl local;

    setUp(() {
      now = DateTime(2026, 10, 22, 9, 41);
      local = PropertiesMockLocalImpl(now: () => now);
    });

    Future<PropertyBookingsEntity> bookingsOf(String id) async {
      return _right(await local.loadBookings(id));
    }

    List<String> ids(List<PropertyBookingEntity> bookings) {
      return <String>[
        for (final PropertyBookingEntity booking in bookings) booking.id,
      ];
    }

    test('splits upcoming (earliest first) from past (latest first)', () async {
      final PropertyBookingsEntity bookings = await bookingsOf(
        PropertiesMockLocalImpl.esentaiId,
      );

      expect(bookings.property.id, PropertiesMockLocalImpl.esentaiId);
      expect(ids(bookings.upcoming), <String>[
        'booking-1042',
        'booking-1047',
        'booking-1053',
        'booking-1058',
      ]);
      expect(ids(bookings.past), <String>['booking-1033', 'booking-1028']);
    });

    test('a finished stay is completed and a cancellation stays', () async {
      final PropertyBookingsEntity bookings = await bookingsOf(
        PropertiesMockLocalImpl.esentaiId,
      );

      expect(
        bookings.past.map((PropertyBookingEntity booking) => booking.status),
        <PropertyBookingStatus>[
          PropertyBookingStatus.cancelled,
          PropertyBookingStatus.completed,
        ],
      );
    });

    test('before check-in a booking keeps its stored status', () async {
      final PropertyBookingsEntity bookings = await bookingsOf(
        PropertiesMockLocalImpl.esentaiId,
      );

      expect(
        bookings.upcoming.map(
          (PropertyBookingEntity booking) => booking.status,
        ),
        <PropertyBookingStatus>[
          PropertyBookingStatus.paid,
          PropertyBookingStatus.confirmed,
          PropertyBookingStatus.pending,
          PropertyBookingStatus.paid,
        ],
      );
      expect(bookings.upcoming[2].isDirect, isTrue);
    });

    test('from check-in the guest is staying', () async {
      now = DateTime(2026, 10, 22, 14);

      final PropertyBookingsEntity bookings = await bookingsOf(
        PropertiesMockLocalImpl.esentaiId,
      );

      expect(bookings.upcoming.first.id, 'booking-1042');
      expect(bookings.upcoming.first.status, PropertyBookingStatus.staying);
    });

    test('at check-out time the stay moves to the past', () async {
      final PropertyBookingsEntity morning = await bookingsOf(
        PropertiesMockLocalImpl.megaTowersId,
      );
      expect(morning.upcoming.first.id, 'booking-1039');
      expect(morning.upcoming.first.status, PropertyBookingStatus.staying);

      now = DateTime(2026, 10, 22, 12);
      final PropertyBookingsEntity noon = await bookingsOf(
        PropertiesMockLocalImpl.megaTowersId,
      );

      expect(ids(noon.upcoming), <String>['booking-1051']);
      expect(ids(noon.past), <String>['booking-1039']);
      expect(noon.past.single.status, PropertyBookingStatus.completed);
    });

    test('the lists cannot be changed by the caller', () async {
      final PropertyBookingsEntity bookings = await bookingsOf(
        PropertiesMockLocalImpl.esentaiId,
      );

      expect(() => bookings.upcoming.clear(), throwsUnsupportedError);
      expect(() => bookings.past.clear(), throwsUnsupportedError);
    });

    test('an unknown property is a 404 for every read and write', () async {
      expect(_left(await local.loadBookings('missing')), _isNotFound);
      expect(_left(await local.loadSettings('missing')), _isNotFound);
      expect(
        _left(
          await local.saveSettings(
            propertyId: 'missing',
            acceptsBookings: true,
          ),
        ),
        _isNotFound,
      );
    });
  });

  group('PropertiesMockLocalImpl settings', () {
    late PropertiesMockLocalImpl local;

    setUp(() {
      local = PropertiesMockLocalImpl(now: () => DateTime(2026, 10, 22, 9, 41));
    });

    test('loads the summary of a sample property', () async {
      final PropertySettingsEntity settings = _right(
        await local.loadSettings(PropertiesMockLocalImpl.esentaiId),
      );

      expect(settings.property.id, PropertiesMockLocalImpl.esentaiId);
      expect(settings.type, PropertyType.apartment);
      expect(settings.terms.pricePerNight, 42500);
      expect(settings.channelErrorCount, 1);
      expect(settings.teamMemberCount, 2);
      expect(settings.acceptsBookings, isTrue);
    });

    test('a saved switch is returned and lasts into later loads', () async {
      final PropertySettingsEntity saved = _right(
        await local.saveSettings(
          propertyId: PropertiesMockLocalImpl.samalId,
          acceptsBookings: false,
        ),
      );

      expect(saved.acceptsBookings, isFalse);
      expect(
        _right(
          await local.loadSettings(PropertiesMockLocalImpl.samalId),
        ).acceptsBookings,
        isFalse,
      );
      expect(
        _right(
          await local.loadSettings(PropertiesMockLocalImpl.esentaiId),
        ).acceptsBookings,
        isTrue,
      );
    });
  });

  group('PropertiesMockLocalImpl add-property draft', () {
    late PropertiesMockLocalImpl local;
    final DateTime now = DateTime(2026, 10, 22, 9, 41);

    setUp(() {
      local = PropertiesMockLocalImpl(now: () => now);
    });

    Future<AddPropertyDraftEntity> draft() async {
      return _right(await local.loadDraft());
    }

    Future<PropertyEntity> publish(String title) async {
      await local.saveDraftDetails(_details(title));
      final String id = _right(await local.publishDraft(_terms));
      final List<PropertyEntity> properties = _right(
        await local.loadProperties(),
      );
      return properties.singleWhere((PropertyEntity p) => p.id == id);
    }

    test('a new draft has no details and the default terms', () async {
      final AddPropertyDraftEntity fresh = await draft();

      expect(fresh.title, isEmpty);
      expect(fresh.address, isEmpty);
      expect(fresh.hasDetails, isFalse);
      expect(fresh.type, PropertyType.apartment);
      expect(fresh.rooms, 2);
      expect(fresh.channels, isEmpty);
      expect(
        fresh.terms,
        const PropertyTermsEntity(
          pricePerNight: 42500,
          deposit: 50000,
          checkInTime: Duration(hours: 14),
          checkOutTime: Duration(hours: 12),
          minNights: 2,
          cleaningFee: 8000,
        ),
      );
    });

    test('details and channels are kept apart from each other', () async {
      await local.saveDraftChannels(const <BookingChannel>[
        BookingChannel.krisha,
      ]);
      await local.saveDraftDetails(_details('Highvill · 5'));

      AddPropertyDraftEntity stored = await draft();
      expect(stored.title, 'Highvill · 5');
      expect(stored.type, PropertyType.house);
      expect(stored.rooms, 3);
      expect(stored.channels, const <BookingChannel>[BookingChannel.krisha]);

      await local.saveDraftChannels(const <BookingChannel>[
        BookingChannel.airbnb,
        BookingChannel.bookingCom,
      ]);
      stored = await draft();
      expect(stored.title, 'Highvill · 5');
      expect(stored.address, 'Аль-Фараби, 21');
      expect(stored.channels, const <BookingChannel>[
        BookingChannel.airbnb,
        BookingChannel.bookingCom,
      ]);
    });

    test('publishing without details is draftIncomplete', () async {
      final Either<Failure, String> result = await local.publishDraft(_terms);

      expect(
        _left(result),
        isA<ValidationFailure>().having(
          (ValidationFailure failure) => failure.code,
          'code',
          PropertyErrorCodes.draftIncomplete,
        ),
      );
      expect(_right(await local.loadProperties()), hasLength(4));
    });

    test('a published property joins the list with the draft values', () async {
      await local.saveDraftChannels(const <BookingChannel>[
        BookingChannel.airbnb,
        BookingChannel.krisha,
      ]);

      final PropertyEntity property = await publish('Al-Farabi Residence · 19');

      expect(property.id, 'new-property-1');
      expect(property.name, 'Al-Farabi Residence');
      expect(property.unit, '19');
      expect(property.city, 'Алматы');
      expect(property.address, 'Аль-Фараби, 21');
      expect(property.rooms, 3);
      expect(property.areaSqm, 0);
      expect(property.maxGuests, 6);
      expect(property.pricePerNight, 30000);
      expect(property.imageUrls, isNotEmpty);
      expect(property.channelNames, <String>['Airbnb', 'Krisha']);
      expect(property.syncedAt, now);
      expect(property.availability.kind, PropertyAvailabilityKind.free);
      expect(property.isFavorite, isFalse);
      expect(property.upcomingStay, isNull);
      expect(_right(await local.loadProperties()), hasLength(5));
    });

    test(
      'a published property is found by id through the repository',
      () async {
        final PropertyEntity property = await publish('Highvill · 7');

        final Either<Failure, PropertyEntity> found =
            await PropertiesRepositoryImpl(local: local)
                .getProperty(property.id);

        expect(found, Right<Failure, PropertyEntity>(property));
      },
    );

    test('publishing resets the draft', () async {
      await local.saveDraftChannels(const <BookingChannel>[
        BookingChannel.airbnb,
      ]);
      await publish('Highvill · 7');

      final AddPropertyDraftEntity fresh = await draft();
      expect(fresh.hasDetails, isFalse);
      expect(fresh.channels, isEmpty);
      expect(fresh.rooms, 2);
      expect(
        _left(await local.publishDraft(_terms)),
        isA<ValidationFailure>(),
      );
    });

    test('each publish gets a new id', () async {
      final PropertyEntity first = await publish('A · 1');
      final PropertyEntity second = await publish('B · 2');

      expect(first.id, 'new-property-1');
      expect(second.id, 'new-property-2');
    });

    test('a published property has settings, bookings, and a heart', () async {
      final PropertyEntity property = await publish('Highvill · 7');

      final PropertySettingsEntity settings = _right(
        await local.loadSettings(property.id),
      );
      expect(settings.type, PropertyType.house);
      expect(settings.terms, _terms);
      expect(settings.acceptsBookings, isTrue);
      expect(settings.houseRules, isEmpty);
      expect(settings.teamMemberCount, 1);
      expect(settings.channelErrorCount, 0);

      final PropertyBookingsEntity bookings = _right(
        await local.loadBookings(property.id),
      );
      expect(bookings.property, property);
      expect(bookings.upcoming, isEmpty);
      expect(bookings.past, isEmpty);

      expect(
        (await local.setFavorite(
          propertyId: property.id,
          isFavorite: true,
        )).isRight,
        isTrue,
      );
      final List<PropertyEntity> properties = _right(
        await local.loadProperties(),
      );
      expect(properties.last.isFavorite, isTrue);
    });

    group('the title is split on the last «·»', () {
      final Map<String, (String, String)> cases = <String, (String, String)>{
        'Al-Farabi Residence · 19': ('Al-Farabi Residence', '19'),
        'Tower · B · 7': ('Tower · B', '7'),
        '  Highvill  ': ('Highvill', ''),
        '· 5': ('· 5', ''),
        'Highvill ·': ('Highvill ·', ''),
      };
      for (final MapEntry<String, (String, String)> entry in cases.entries) {
        test('«${entry.key}» → ${entry.value}', () async {
          final PropertyEntity property = await publish(entry.key);

          expect((property.name, property.unit), entry.value);
        });
      }
    });
  });
}
