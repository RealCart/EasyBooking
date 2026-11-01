import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
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
import 'package:easy_booking/features/properties/domain/entity/upcoming_stay_entity.dart';

/// Four sample apartments until the properties API exists.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Favorites live in memory, so they last
/// until the app restarts. Replace it with a `PropertiesRemote` returning
/// models when the endpoints are ready.
abstract interface class PropertiesMockLocal {
  Future<Either<Failure, List<PropertyEntity>>> loadProperties();

  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  });
}

/// Bookings, settings, and the add-property draft of the same in-memory
/// properties, so a published property appears in [loadProperties].
///
/// It implements [PropertiesMockLocal] so that one instance serves both
/// contracts. Unknown property ids are a 404 [ServerFailure].
abstract interface class PropertyManagementMockLocal
    implements PropertiesMockLocal {
  Future<Either<Failure, PropertyBookingsEntity>> loadBookings(
    String propertyId,
  );

  Future<Either<Failure, PropertySettingsEntity>> loadSettings(
    String propertyId,
  );

  /// Returns the settings as stored.
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  });

  Future<Either<Failure, AddPropertyDraftEntity>> loadDraft();

  Future<Either<Failure, void>> saveDraftDetails(
    SaveAddPropertyDetailsParamsEntity details,
  );

  Future<Either<Failure, void>> saveDraftChannels(
    List<BookingChannel> channels,
  );

  /// Adds the draft as a property with [terms], resets the draft, and
  /// returns the new id. Fails with [PropertyErrorCodes.draftIncomplete]
  /// before the draft details were saved.
  Future<Either<Failure, String>> publishDraft(PropertyTermsEntity terms);
}

final class PropertiesMockLocalImpl implements PropertyManagementMockLocal {
  /// [now] supplies the current time, so bookings are relative to today.
  PropertiesMockLocalImpl({required this._now});

  static const String esentaiId = 'esentai-city-84';
  static const String megaTowersId = 'mega-towers-126';
  static const String samalId = 'samal-residence';
  static const String highvillId = 'highvill-5';

  static const Set<String> _allIds = <String>{
    esentaiId,
    megaTowersId,
    samalId,
    highvillId,
  };

  /// What a new property gets before the user uploads photos: the property
  /// screens need at least one image. Photo upload does not exist yet.
  static final String _placeholderImage =
      AppAssets.images.propertyLivingRoomWarm;

  /// City of new properties: the form has no city field yet.
  static const String _defaultCity = 'Алматы';

  /// The values step 3 of «Добавить квартиру» starts with, as in the design.
  static const PropertyTermsEntity _defaultTerms = PropertyTermsEntity(
    pricePerNight: 42500,
    deposit: 50000,
    checkInTime: Duration(hours: 14),
    checkOutTime: Duration(hours: 12),
    minNights: 2,
    cleaningFee: 8000,
  );

  static const AddPropertyDraftEntity _emptyDraft = AddPropertyDraftEntity(
    title: '',
    address: '',
    type: PropertyType.apartment,
    rooms: 2,
    channels: <BookingChannel>[],
    terms: _defaultTerms,
  );

  final DateTime Function() _now;

  final Set<String> _favoriteIds = <String>{esentaiId, megaTowersId};

  /// Properties published through the draft, in publish order.
  final List<_CreatedProperty> _created = <_CreatedProperty>[];
  int _lastCreatedNumber = 0;

  AddPropertyDraftEntity _draft = _emptyDraft;

  final Map<String, bool> _acceptsBookings = <String, bool>{
    esentaiId: true,
    megaTowersId: true,
    samalId: true,
    highvillId: true,
  };

  bool _isKnown(String propertyId) {
    return _allIds.contains(propertyId) ||
        _created.any((_CreatedProperty item) => item.id == propertyId);
  }

  static Left<Failure, T> _unknown<T>(String propertyId) {
    return Left<Failure, T>(
      ServerFailure(statusCode: 404, message: 'Unknown property $propertyId'),
    );
  }

  @override
  Future<Either<Failure, List<PropertyEntity>>> loadProperties() async {
    final DateTime now = _now();

    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    final DateTime syncedAt = now.subtract(const Duration(minutes: 3));
    final String warm = AppAssets.images.propertyLivingRoomWarm;
    final String blue = AppAssets.images.propertyLivingRoomBlue;
    final String dining = AppAssets.images.propertyDiningRoom;

    return Right<Failure, List<PropertyEntity>>(
      List<PropertyEntity>.unmodifiable(<PropertyEntity>[
        PropertyEntity(
          id: esentaiId,
          name: 'Esentai City',
          unit: '84',
          city: 'Алматы',
          address: 'Аль-Фараби, 77/8',
          rooms: 2,
          areaSqm: 54,
          maxGuests: 4,
          pricePerNight: 42500,
          imageUrls: <String>[warm, dining, blue],
          channelNames: const <String>['Booking.com', 'Airbnb'],
          syncedAt: syncedAt,
          availability: PropertyAvailabilityEntity(
            kind: PropertyAvailabilityKind.checkInToday,
            at: at(0, 14),
          ),
          isFavorite: _favoriteIds.contains(esentaiId),
          receivedAt: now,
          upcomingStay: UpcomingStayEntity(
            bookingId: 'booking-1042',
            guestName: 'Айжан Сарсенова',
            checkIn: at(0, 14),
            checkOut: at(3, 12),
            guestCount: 2,
          ),
        ),
        PropertyEntity(
          id: megaTowersId,
          name: 'Mega Towers',
          unit: '126',
          city: 'Алматы',
          address: 'Каблукова, 264',
          rooms: 1,
          areaSqm: 38,
          maxGuests: 2,
          pricePerNight: 32000,
          imageUrls: <String>[blue, warm],
          channelNames: const <String>['Airbnb'],
          syncedAt: syncedAt,
          availability: PropertyAvailabilityEntity(
            kind: PropertyAvailabilityKind.freeUntil,
            at: at(3, 15),
          ),
          isFavorite: _favoriteIds.contains(megaTowersId),
          receivedAt: now,
          upcomingStay: UpcomingStayEntity(
            bookingId: 'booking-1051',
            guestName: 'Тимур Абенов',
            checkIn: at(3, 15),
            checkOut: at(5, 12),
            guestCount: 1,
          ),
        ),
        PropertyEntity(
          id: samalId,
          name: 'Samal Residence',
          unit: '12',
          city: 'Алматы',
          address: 'Самал-2, 58',
          rooms: 2,
          areaSqm: 61,
          maxGuests: 4,
          pricePerNight: 38000,
          imageUrls: <String>[dining, blue],
          channelNames: const <String>['Booking.com'],
          syncedAt: syncedAt,
          availability: PropertyAvailabilityEntity(
            kind: PropertyAvailabilityKind.checkInToday,
            at: at(0, 18, 30),
          ),
          isFavorite: _favoriteIds.contains(samalId),
          receivedAt: now,
          upcomingStay: UpcomingStayEntity(
            bookingId: 'booking-1044',
            guestName: 'Данияр Муратов',
            checkIn: at(0, 18, 30),
            checkOut: at(2, 12),
            guestCount: 3,
          ),
        ),
        PropertyEntity(
          id: highvillId,
          name: 'Highvill',
          unit: '5',
          city: 'Алматы',
          address: 'Кабанбай батыра, 11',
          rooms: 3,
          areaSqm: 86,
          maxGuests: 6,
          pricePerNight: 55000,
          imageUrls: <String>[blue, dining, warm],
          channelNames: const <String>['Booking.com', 'Airbnb'],
          syncedAt: syncedAt,
          availability: PropertyAvailabilityEntity(
            kind: PropertyAvailabilityKind.occupied,
            at: at(2, 12),
          ),
          isFavorite: _favoriteIds.contains(highvillId),
          receivedAt: now,
          upcomingStay: UpcomingStayEntity(
            bookingId: 'booking-1034',
            guestName: 'Мадина Касымова',
            checkIn: at(-1, 15),
            checkOut: at(2, 12),
            guestCount: 2,
          ),
        ),
        for (final _CreatedProperty created in _created)
          created.property.copyWith(
            isFavorite: _favoriteIds.contains(created.id),
            receivedAt: now,
          ),
      ]),
    );
  }

  @override
  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  }) async {
    if (!_isKnown(propertyId)) {
      return _unknown<void>(propertyId);
    }
    if (isFavorite) {
      _favoriteIds.add(propertyId);
    } else {
      _favoriteIds.remove(propertyId);
    }
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, PropertyBookingsEntity>> loadBookings(
    String propertyId,
  ) async {
    final Either<Failure, PropertyEntity> result = await _findProperty(
      propertyId,
    );
    return result.map((PropertyEntity property) {
      final DateTime now = _now();
      final List<PropertyBookingEntity> upcoming = <PropertyBookingEntity>[];
      final List<PropertyBookingEntity> past = <PropertyBookingEntity>[];
      for (final PropertyBookingEntity booking in _bookingsOf(
        propertyId,
        now,
      )) {
        final PropertyBookingEntity current = _withStatusAt(booking, now);
        if (current.status == PropertyBookingStatus.cancelled ||
            current.status == PropertyBookingStatus.completed) {
          past.add(current);
        } else {
          upcoming.add(current);
        }
      }
      upcoming.sort(
        (PropertyBookingEntity a, PropertyBookingEntity b) =>
            a.checkIn.compareTo(b.checkIn),
      );
      past.sort(
        (PropertyBookingEntity a, PropertyBookingEntity b) =>
            b.checkIn.compareTo(a.checkIn),
      );
      return PropertyBookingsEntity(
        property: property,
        upcoming: List<PropertyBookingEntity>.unmodifiable(upcoming),
        past: List<PropertyBookingEntity>.unmodifiable(past),
        receivedAt: now,
      );
    });
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> loadSettings(
    String propertyId,
  ) async {
    final Either<Failure, PropertyEntity> result = await _findProperty(
      propertyId,
    );
    return result.map(_settingsOf);
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  }) async {
    if (!_isKnown(propertyId)) {
      return _unknown<PropertySettingsEntity>(propertyId);
    }
    _acceptsBookings[propertyId] = acceptsBookings;
    return loadSettings(propertyId);
  }

  @override
  Future<Either<Failure, AddPropertyDraftEntity>> loadDraft() async {
    return Right<Failure, AddPropertyDraftEntity>(_draft);
  }

  @override
  Future<Either<Failure, void>> saveDraftDetails(
    SaveAddPropertyDetailsParamsEntity details,
  ) async {
    _draft = AddPropertyDraftEntity(
      title: details.title,
      address: details.address,
      type: details.type,
      rooms: details.rooms,
      channels: _draft.channels,
      terms: _draft.terms,
    );
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, void>> saveDraftChannels(
    List<BookingChannel> channels,
  ) async {
    _draft = AddPropertyDraftEntity(
      title: _draft.title,
      address: _draft.address,
      type: _draft.type,
      rooms: _draft.rooms,
      channels: List<BookingChannel>.unmodifiable(channels),
      terms: _draft.terms,
    );
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, String>> publishDraft(
    PropertyTermsEntity terms,
  ) async {
    final AddPropertyDraftEntity draft = _draft;
    if (!draft.hasDetails) {
      return const Left<Failure, String>(
        ValidationFailure(
          code: PropertyErrorCodes.draftIncomplete,
          message: 'The draft has no details yet',
        ),
      );
    }

    final DateTime now = _now();
    _lastCreatedNumber += 1;
    final String id = 'new-property-$_lastCreatedNumber';
    final (String name, String unit) = _splitTitle(draft.title);
    _created.add(
      _CreatedProperty(
        property: PropertyEntity(
          id: id,
          name: name,
          unit: unit,
          city: _defaultCity,
          address: draft.address,
          rooms: draft.rooms,
          // The form asks for neither; 0 means unknown area.
          areaSqm: 0,
          maxGuests: draft.rooms * 2,
          pricePerNight: terms.pricePerNight,
          imageUrls: <String>[_placeholderImage],
          channelNames: List<String>.unmodifiable(
            draft.channels.map((BookingChannel channel) => channel.title),
          ),
          syncedAt: now,
          availability: const PropertyAvailabilityEntity(
            kind: PropertyAvailabilityKind.free,
          ),
          isFavorite: false,
          receivedAt: now,
        ),
        extras: _PropertyExtras(
          type: draft.type,
          terms: terms,
          houseRules: const <String>[],
          channelErrorCount: 0,
          teamMemberCount: 1,
          guestInstructionTopics: const <String>[],
        ),
      ),
    );
    _acceptsBookings[id] = true;
    _draft = _emptyDraft;
    return Right<Failure, String>(id);
  }

  Future<Either<Failure, PropertyEntity>> _findProperty(
    String propertyId,
  ) async {
    final Either<Failure, List<PropertyEntity>> result = await loadProperties();
    return result.flatMap((List<PropertyEntity> properties) {
      for (final PropertyEntity property in properties) {
        if (property.id == propertyId) {
          return Right<Failure, PropertyEntity>(property);
        }
      }
      return _unknown<PropertyEntity>(propertyId);
    });
  }

  PropertySettingsEntity _settingsOf(PropertyEntity property) {
    final _PropertyExtras extras = _extrasOf(property.id);
    return PropertySettingsEntity(
      property: property,
      type: extras.type,
      terms: extras.terms,
      houseRules: extras.houseRules,
      channelErrorCount: extras.channelErrorCount,
      teamMemberCount: extras.teamMemberCount,
      guestInstructionTopics: extras.guestInstructionTopics,
      acceptsBookings: _acceptsBookings[property.id] ?? true,
    );
  }

  /// Only called for known ids.
  _PropertyExtras _extrasOf(String propertyId) {
    for (final _CreatedProperty created in _created) {
      if (created.id == propertyId) {
        return created.extras;
      }
    }
    return switch (propertyId) {
      esentaiId => const _PropertyExtras(
        type: PropertyType.apartment,
        terms: _defaultTerms,
        houseRules: <String>['Не курить', 'Без вечеринок'],
        // Matches the failed Airbnb import in the notifications mock.
        channelErrorCount: 1,
        teamMemberCount: 2,
        guestInstructionTopics: <String>['Домофон', 'Wi-Fi', 'Заселение'],
      ),
      megaTowersId => const _PropertyExtras(
        type: PropertyType.apartment,
        terms: PropertyTermsEntity(
          pricePerNight: 32000,
          deposit: 30000,
          checkInTime: Duration(hours: 15),
          checkOutTime: Duration(hours: 12),
          minNights: 1,
          cleaningFee: 6000,
        ),
        houseRules: <String>['Не курить'],
        channelErrorCount: 0,
        teamMemberCount: 2,
        guestInstructionTopics: <String>['Домофон', 'Wi-Fi'],
      ),
      samalId => const _PropertyExtras(
        type: PropertyType.apartment,
        terms: PropertyTermsEntity(
          pricePerNight: 38000,
          deposit: 40000,
          checkInTime: Duration(hours: 14),
          checkOutTime: Duration(hours: 12),
          minNights: 2,
          cleaningFee: 7000,
        ),
        houseRules: <String>['Не курить', 'Без животных'],
        channelErrorCount: 0,
        teamMemberCount: 1,
        guestInstructionTopics: <String>['Wi-Fi', 'Заселение'],
      ),
      _ => const _PropertyExtras(
        type: PropertyType.apartment,
        terms: PropertyTermsEntity(
          pricePerNight: 55000,
          deposit: 60000,
          checkInTime: Duration(hours: 15),
          checkOutTime: Duration(hours: 11),
          minNights: 2,
          cleaningFee: 10000,
        ),
        houseRules: <String>[
          'Не курить',
          'Без вечеринок',
          'Тишина после 23:00',
        ],
        channelErrorCount: 0,
        teamMemberCount: 3,
        guestInstructionTopics: <String>[],
      ),
    };
  }

  /// The bookings of [propertyId] with their stored status: every booking
  /// of the property in the bookings mock, with the same guests, dates,
  /// channels, and prices. Samal Residence lists both of its apartments,
  /// 12 and 7, since a booking here has no unit.
  List<PropertyBookingEntity> _bookingsOf(String propertyId, DateTime now) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    return switch (propertyId) {
      esentaiId => <PropertyBookingEntity>[
        PropertyBookingEntity(
          id: 'booking-0964',
          guestName: 'Мария Жукова',
          checkIn: at(-45, 14),
          checkOut: at(-41, 12),
          guestCount: 2,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.paid,
          totalPrice: 170000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1028',
          guestName: 'Ерлан Жумабеков',
          checkIn: at(-9, 14),
          checkOut: at(-6, 12),
          guestCount: 2,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 127500,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1033',
          guestName: 'Ксения Ли',
          checkIn: at(-5, 15),
          checkOut: at(-3, 12),
          guestCount: 1,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.cancelled,
          totalPrice: 85000,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-1042',
          guestName: 'Айжан Сарсенова',
          checkIn: at(0, 14),
          checkOut: at(3, 12),
          guestCount: 2,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 127500,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1046',
          guestName: 'Марат Ильясов',
          checkIn: at(2, 14),
          checkOut: at(5, 12),
          guestCount: 2,
          status: PropertyBookingStatus.pending,
          totalPrice: 114000,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-1047',
          guestName: 'Олег Беляев',
          checkIn: at(3, 14),
          checkOut: at(6, 12),
          guestCount: 2,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.confirmed,
          totalPrice: 138000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1053',
          guestName: 'Марат Ильясов',
          checkIn: at(6, 14),
          checkOut: at(9, 12),
          guestCount: 3,
          status: PropertyBookingStatus.pending,
          totalPrice: 127500,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-1058',
          guestName: 'Алина Чехова',
          checkIn: at(11, 14),
          checkOut: at(15, 12),
          guestCount: 2,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 170000,
          hasContract: true,
        ),
      ],
      megaTowersId => <PropertyBookingEntity>[
        PropertyBookingEntity(
          id: 'booking-0912',
          guestName: 'Айжан Сарсенова',
          checkIn: at(-106, 15),
          checkOut: at(-103, 12),
          guestCount: 2,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 96000,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-0941',
          guestName: 'Дина Ким',
          checkIn: at(-60, 15),
          checkOut: at(-57, 12),
          guestCount: 1,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 96000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1039',
          guestName: 'Арман Темирбек',
          checkIn: at(-2, 15),
          checkOut: at(0, 12),
          guestCount: 2,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 64000,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-1051',
          guestName: 'Тимур Абенов',
          checkIn: at(3, 15),
          checkOut: at(5, 12),
          guestCount: 1,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.confirmed,
          totalPrice: 64000,
          hasContract: true,
        ),
      ],
      samalId => <PropertyBookingEntity>[
        PropertyBookingEntity(
          id: 'booking-1012',
          guestName: 'Руслан Ибраев',
          checkIn: at(-27, 14),
          checkOut: at(-24, 12),
          guestCount: 2,
          status: PropertyBookingStatus.paid,
          totalPrice: 114000,
          hasContract: false,
        ),
        PropertyBookingEntity(
          id: 'booking-1036',
          guestName: 'Гульнара Ахметова',
          checkIn: at(-7, 14),
          checkOut: at(-4, 12),
          guestCount: 2,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.paid,
          totalPrice: 114000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1044',
          guestName: 'Данияр Муратов',
          checkIn: at(0, 18, 30),
          checkOut: at(2, 12),
          guestCount: 3,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.confirmed,
          totalPrice: 76000,
          hasContract: true,
        ),
        // Apartment 7.
        PropertyBookingEntity(
          id: 'booking-1037',
          guestName: 'Асель Нурланова',
          checkIn: at(-2, 16),
          checkOut: at(4, 12),
          guestCount: 2,
          status: PropertyBookingStatus.paid,
          totalPrice: 228000,
          hasContract: true,
        ),
      ],
      highvillId => <PropertyBookingEntity>[
        PropertyBookingEntity(
          id: 'booking-0918',
          guestName: 'Сергей Пак',
          checkIn: at(-75, 15),
          checkOut: at(-70, 12),
          guestCount: 2,
          status: PropertyBookingStatus.paid,
          totalPrice: 275000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1019',
          guestName: 'Камила Ахметова',
          checkIn: at(-20, 15),
          checkOut: at(-16, 12),
          guestCount: 3,
          channel: BookingChannel.bookingCom,
          status: PropertyBookingStatus.paid,
          totalPrice: 220000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1025',
          guestName: 'Иван Петров',
          checkIn: at(-12, 15),
          checkOut: at(-9, 11),
          guestCount: 5,
          channel: BookingChannel.airbnb,
          status: PropertyBookingStatus.paid,
          totalPrice: 165000,
          hasContract: true,
        ),
        PropertyBookingEntity(
          id: 'booking-1034',
          guestName: 'Мадина Касымова',
          checkIn: at(-1, 15),
          checkOut: at(2, 12),
          guestCount: 2,
          status: PropertyBookingStatus.paid,
          totalPrice: 165000,
          hasContract: true,
        ),
      ],
      // A published property has no bookings yet.
      _ => const <PropertyBookingEntity>[],
    };
  }

  /// [booking] with the status it has at [now]: staying between check-in
  /// and check-out, completed after check-out. A cancellation stays.
  static PropertyBookingEntity _withStatusAt(
    PropertyBookingEntity booking,
    DateTime now,
  ) {
    final PropertyBookingStatus status;
    if (booking.status == PropertyBookingStatus.cancelled) {
      status = PropertyBookingStatus.cancelled;
    } else if (!now.isBefore(booking.checkOut)) {
      status = PropertyBookingStatus.completed;
    } else if (!now.isBefore(booking.checkIn)) {
      status = PropertyBookingStatus.staying;
    } else {
      status = booking.status;
    }
    if (status == booking.status) {
      return booking;
    }
    return PropertyBookingEntity(
      id: booking.id,
      guestName: booking.guestName,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      guestCount: booking.guestCount,
      channel: booking.channel,
      status: status,
      totalPrice: booking.totalPrice,
      hasContract: booking.hasContract,
    );
  }

  /// `Al-Farabi Residence · 19` → (`Al-Farabi Residence`, `19`). Without a
  /// `·` the whole title is the name and the unit is empty.
  static (String, String) _splitTitle(String title) {
    final int separator = title.lastIndexOf('·');
    if (separator <= 0) {
      return (title.trim(), '');
    }
    final String name = title.substring(0, separator).trim();
    final String unit = title.substring(separator + 1).trim();
    if (name.isEmpty || unit.isEmpty) {
      return (title.trim(), '');
    }
    return (name, unit);
  }
}

/// A property published through the draft, with what only settings show.
final class _CreatedProperty {
  const _CreatedProperty({required this.property, required this.extras});

  final PropertyEntity property;
  final _PropertyExtras extras;

  String get id => property.id;
}

/// The settings of a property that [PropertyEntity] does not hold.
final class _PropertyExtras {
  const _PropertyExtras({
    required this.type,
    required this.terms,
    required this.houseRules,
    required this.channelErrorCount,
    required this.teamMemberCount,
    required this.guestInstructionTopics,
  });

  final PropertyType type;
  final PropertyTermsEntity terms;
  final List<String> houseRules;
  final int channelErrorCount;
  final int teamMemberCount;
  final List<String> guestInstructionTopics;
}
