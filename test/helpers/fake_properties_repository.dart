import 'dart:async';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/upcoming_stay_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

/// The source's current time in the tests: 22 October 2026, 09:41.
final DateTime propertiesTestNow = DateTime(2026, 10, 22, 9, 41);

/// A busy favorite `p1` (Esentai City · 84, 42 500 ₸) and a free `p2`
/// (Mega Towers · 126, 32 000 ₸).
List<PropertyEntity> testProperties() {
  return <PropertyEntity>[
    PropertyEntity(
      id: 'p1',
      name: 'Esentai City',
      unit: '84',
      city: 'Алматы',
      address: 'Аль-Фараби, 77/8',
      rooms: 2,
      areaSqm: 54,
      maxGuests: 4,
      pricePerNight: 42500,
      imageUrls: <String>[
        AppAssets.images.propertyLivingRoomWarm,
        AppAssets.images.propertyDiningRoom,
      ],
      channelNames: const <String>['Booking.com', 'Airbnb'],
      syncedAt: DateTime(2026, 10, 22, 9, 38),
      availability: PropertyAvailabilityEntity(
        kind: PropertyAvailabilityKind.checkInToday,
        at: DateTime(2026, 10, 22, 14),
      ),
      isFavorite: true,
      receivedAt: propertiesTestNow,
      upcomingStay: UpcomingStayEntity(
        bookingId: 'b1',
        guestName: 'Айжан Сарсенова',
        checkIn: DateTime(2026, 10, 22, 14),
        checkOut: DateTime(2026, 10, 25, 12),
        guestCount: 2,
      ),
    ),
    PropertyEntity(
      id: 'p2',
      name: 'Mega Towers',
      unit: '126',
      city: 'Алматы',
      address: 'Каблукова, 264',
      rooms: 1,
      areaSqm: 38,
      maxGuests: 2,
      pricePerNight: 32000,
      imageUrls: <String>[AppAssets.images.propertyLivingRoomBlue],
      channelNames: const <String>['Airbnb'],
      syncedAt: DateTime(2026, 10, 22, 9, 38),
      availability: PropertyAvailabilityEntity(
        kind: PropertyAvailabilityKind.freeUntil,
        at: DateTime(2026, 10, 25, 14),
      ),
      isFavorite: false,
      receivedAt: propertiesTestNow,
    ),
  ];
}

/// [PropertiesRepository] over [testProperties] that records writes.
///
/// Set [holdProperties] to keep the next list requests pending; each gets a
/// completer in [heldProperties].
final class FakePropertiesRepository implements PropertiesRepository {
  Either<Failure, List<PropertyEntity>> propertiesResult =
      Right<Failure, List<PropertyEntity>>(testProperties());
  Either<Failure, void> setFavoriteResult = const Right<Failure, void>(null);

  bool holdProperties = false;
  final List<Completer<Either<Failure, List<PropertyEntity>>>> heldProperties =
      <Completer<Either<Failure, List<PropertyEntity>>>>[];

  int propertiesCount = 0;
  final List<({String propertyId, bool isFavorite})> favoriteCalls =
      <({String propertyId, bool isFavorite})>[];

  @override
  Future<Either<Failure, List<PropertyEntity>>> getProperties() async {
    propertiesCount += 1;
    if (!holdProperties) {
      return propertiesResult;
    }
    final Completer<Either<Failure, List<PropertyEntity>>> completer =
        Completer<Either<Failure, List<PropertyEntity>>>();
    heldProperties.add(completer);
    return completer.future;
  }

  /// Ids passed to [getProperty], in call order.
  final List<String> propertyIds = <String>[];

  /// When set, [getProperty] waits for it before answering from
  /// [propertiesResult], so a test can see the loading state.
  Completer<void>? propertyGate;

  @override
  Future<Either<Failure, PropertyEntity>> getProperty(String id) async {
    propertyIds.add(id);
    final Completer<void>? gate = propertyGate;
    if (gate != null) {
      await gate.future;
    }
    return propertiesResult.flatMap((List<PropertyEntity> properties) {
      for (final PropertyEntity property in properties) {
        if (property.id == id) {
          return Right<Failure, PropertyEntity>(property);
        }
      }
      return const Left<Failure, PropertyEntity>(
        ServerFailure(statusCode: 404),
      );
    });
  }

  @override
  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  }) async {
    favoriteCalls.add((propertyId: propertyId, isFavorite: isFavorite));
    return setFavoriteResult;
  }
}
