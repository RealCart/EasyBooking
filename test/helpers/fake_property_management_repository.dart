import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

import 'fake_properties_repository.dart';

/// The terms of the add-property draft in the tests.
const PropertyTermsEntity testTerms = PropertyTermsEntity(
  pricePerNight: 42500,
  deposit: 50000,
  checkInTime: Duration(hours: 14),
  checkOutTime: Duration(hours: 12),
  minNights: 2,
  cleaningFee: 8000,
);

/// A fresh draft: no details, no channels, [testTerms].
const AddPropertyDraftEntity testEmptyDraft = AddPropertyDraftEntity(
  title: '',
  address: '',
  type: PropertyType.apartment,
  rooms: 2,
  channels: <BookingChannel>[],
  terms: testTerms,
);

/// A draft after steps 1 and 2: a house with three rooms on Airbnb.
const AddPropertyDraftEntity testFilledDraft = AddPropertyDraftEntity(
  title: 'Al-Farabi Residence · 19',
  address: 'Аль-Фараби, 21',
  type: PropertyType.house,
  rooms: 3,
  channels: <BookingChannel>[BookingChannel.airbnb],
  terms: testTerms,
);

/// Bookings of `p1` ([testProperties] first) around [propertiesTestNow]
/// (22 October 2026): three upcoming in October and November, two past.
/// [receivedAt], the source's time, defaults to [propertiesTestNow].
PropertyBookingsEntity testPropertyBookings({DateTime? receivedAt}) {
  return PropertyBookingsEntity(
    property: testProperties().first,
    upcoming: <PropertyBookingEntity>[
      PropertyBookingEntity(
        id: 'b-staying',
        guestName: 'Айжан Сарсенова',
        checkIn: DateTime(2026, 10, 20, 14),
        checkOut: DateTime(2026, 10, 23, 12),
        guestCount: 2,
        channel: BookingChannel.airbnb,
        status: PropertyBookingStatus.staying,
        totalPrice: 127500,
        hasContract: true,
      ),
      PropertyBookingEntity(
        id: 'b-direct',
        guestName: 'Марат Ильясов',
        checkIn: DateTime(2026, 10, 28, 14),
        checkOut: DateTime(2026, 10, 31, 12),
        guestCount: 3,
        status: PropertyBookingStatus.pending,
        totalPrice: 127500,
        hasContract: false,
      ),
      PropertyBookingEntity(
        id: 'b-confirmed',
        guestName: 'Олег Беляев',
        checkIn: DateTime(2026, 11, 3, 14),
        checkOut: DateTime(2026, 11, 6, 12),
        guestCount: 2,
        channel: BookingChannel.bookingCom,
        status: PropertyBookingStatus.confirmed,
        totalPrice: 138000,
        hasContract: true,
      ),
    ],
    past: <PropertyBookingEntity>[
      PropertyBookingEntity(
        id: 'b-cancelled',
        guestName: 'Ксения Ли',
        checkIn: DateTime(2026, 10, 17, 15),
        checkOut: DateTime(2026, 10, 19, 12),
        guestCount: 1,
        channel: BookingChannel.bookingCom,
        status: PropertyBookingStatus.cancelled,
        totalPrice: 85000,
        hasContract: false,
      ),
      PropertyBookingEntity(
        id: 'b-completed',
        guestName: 'Ерлан Жумабеков',
        checkIn: DateTime(2026, 10, 13, 14),
        checkOut: DateTime(2026, 10, 16, 12),
        guestCount: 2,
        channel: BookingChannel.airbnb,
        status: PropertyBookingStatus.completed,
        totalPrice: 127500,
        hasContract: true,
      ),
    ],
    receivedAt: receivedAt ?? propertiesTestNow,
  );
}

/// Settings of `p1` ([testProperties] first), accepting bookings.
PropertySettingsEntity testPropertySettings({bool acceptsBookings = true}) {
  return PropertySettingsEntity(
    property: testProperties().first,
    type: PropertyType.apartment,
    terms: testTerms,
    houseRules: const <String>['Не курить', 'Без вечеринок'],
    channelErrorCount: 1,
    teamMemberCount: 2,
    guestInstructionTopics: const <String>['Домофон', 'Wi-Fi'],
    acceptsBookings: acceptsBookings,
  );
}

/// [PropertyManagementRepository] with settable results that records every
/// call.
///
/// Set a `hold*` flag to keep the next requests of that kind pending; each
/// gets a completer in the matching `held*` list.
final class FakePropertyManagementRepository
    implements PropertyManagementRepository {
  Either<Failure, PropertyBookingsEntity> bookingsResult =
      Right<Failure, PropertyBookingsEntity>(testPropertyBookings());
  Either<Failure, PropertySettingsEntity> settingsResult =
      Right<Failure, PropertySettingsEntity>(testPropertySettings());

  /// `null` returns the stored settings with the saved switch.
  Either<Failure, PropertySettingsEntity>? saveSettingsResult;
  Either<Failure, AddPropertyDraftEntity> draftResult =
      const Right<Failure, AddPropertyDraftEntity>(testEmptyDraft);
  Either<Failure, void> saveDetailsResult = const Right<Failure, void>(null);
  Either<Failure, void> saveChannelsResult = const Right<Failure, void>(null);
  Either<Failure, String> publishResult = const Right<Failure, String>(
    'new-property-1',
  );

  bool holdBookings = false;
  bool holdSettings = false;
  bool holdSaveSettings = false;
  bool holdDraft = false;
  bool holdSaveDetails = false;
  bool holdPublish = false;

  final List<Completer<Either<Failure, PropertyBookingsEntity>>> heldBookings =
      <Completer<Either<Failure, PropertyBookingsEntity>>>[];
  final List<Completer<Either<Failure, PropertySettingsEntity>>> heldSettings =
      <Completer<Either<Failure, PropertySettingsEntity>>>[];
  final List<Completer<Either<Failure, PropertySettingsEntity>>>
  heldSaveSettings = <Completer<Either<Failure, PropertySettingsEntity>>>[];
  final List<Completer<Either<Failure, AddPropertyDraftEntity>>> heldDraft =
      <Completer<Either<Failure, AddPropertyDraftEntity>>>[];
  final List<Completer<Either<Failure, void>>> heldSaveDetails =
      <Completer<Either<Failure, void>>>[];
  final List<Completer<Either<Failure, String>>> heldPublish =
      <Completer<Either<Failure, String>>>[];

  final List<String> bookingsIds = <String>[];
  final List<String> settingsIds = <String>[];
  final List<({String propertyId, bool acceptsBookings})> saveSettingsCalls =
      <({String propertyId, bool acceptsBookings})>[];
  int draftCount = 0;
  final List<SaveAddPropertyDetailsParamsEntity> savedDetails =
      <SaveAddPropertyDetailsParamsEntity>[];
  final List<List<BookingChannel>> savedChannels = <List<BookingChannel>>[];
  final List<PropertyTermsEntity> publishedTerms = <PropertyTermsEntity>[];

  static Future<T> _respond<T>(
    bool hold,
    List<Completer<T>> held,
    T result,
  ) async {
    if (!hold) {
      return result;
    }
    final Completer<T> completer = Completer<T>();
    held.add(completer);
    return completer.future;
  }

  @override
  Future<Either<Failure, PropertyBookingsEntity>> getBookings(
    String propertyId,
  ) {
    bookingsIds.add(propertyId);
    return _respond(holdBookings, heldBookings, bookingsResult);
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> getSettings(
    String propertyId,
  ) {
    settingsIds.add(propertyId);
    return _respond(holdSettings, heldSettings, settingsResult);
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  }) {
    saveSettingsCalls.add((
      propertyId: propertyId,
      acceptsBookings: acceptsBookings,
    ));
    final Either<Failure, PropertySettingsEntity> result =
        saveSettingsResult ??
        Right<Failure, PropertySettingsEntity>(
          testPropertySettings(acceptsBookings: acceptsBookings),
        );
    return _respond(holdSaveSettings, heldSaveSettings, result);
  }

  @override
  Future<Either<Failure, AddPropertyDraftEntity>> getAddPropertyDraft() {
    draftCount += 1;
    return _respond(holdDraft, heldDraft, draftResult);
  }

  @override
  Future<Either<Failure, void>> saveAddPropertyDetails(
    SaveAddPropertyDetailsParamsEntity details,
  ) {
    savedDetails.add(details);
    return _respond(holdSaveDetails, heldSaveDetails, saveDetailsResult);
  }

  @override
  Future<Either<Failure, void>> saveAddPropertyChannels(
    List<BookingChannel> channels,
  ) async {
    savedChannels.add(channels);
    return saveChannelsResult;
  }

  @override
  Future<Either<Failure, String>> publishProperty(PropertyTermsEntity terms) {
    publishedTerms.add(terms);
    return _respond(holdPublish, heldPublish, publishResult);
  }
}
