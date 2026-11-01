import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/data/sources/local/bookings_mock_local.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

/// Reads and writes through [BookingsMockLocal], which already returns
/// entities. The mock has no property catalog, so [saveDraft] first asks
/// [PropertiesRepository] for the property, through its domain contract;
/// an unknown property fails before the draft is saved.
final class BookingsRepositoryImpl implements BookingsRepository {
  const BookingsRepositoryImpl({
    required this._local,
    required this._properties,
  });

  final BookingsMockLocal _local;
  final PropertiesRepository _properties;

  @override
  Future<Either<Failure, BookingEntity>> getBooking(String id) {
    return _local.loadBooking(id);
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) {
    return _local.cancelBooking(id);
  }

  @override
  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(
    String query,
  ) {
    return _local.searchGuests(query);
  }

  @override
  Future<Either<Failure, CurrentBookingDraftEntity>> getDraft() {
    return _local.loadDraft();
  }

  @override
  Future<Either<Failure, BookingDraftEntity>> saveDraft(
    SaveBookingDraftParamsEntity params,
  ) async {
    final Either<Failure, PropertyEntity> property = await _properties
        .getProperty(params.propertyId);
    return property.flatMapAsync(
      (PropertyEntity property) =>
          _local.saveDraft(params: params, property: property),
    );
  }

  @override
  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  ) {
    return _local.createBooking(params);
  }
}
