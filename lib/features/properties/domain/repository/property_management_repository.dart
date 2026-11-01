import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';

/// Managing properties: their bookings and settings, and adding new ones.
///
/// Served by the same mock source as `PropertiesRepository`, so a published
/// property appears in its list. Kept apart from it so that its contract
/// stays as the property list screens use it.
abstract interface class PropertyManagementRepository {
  /// The bookings of [propertyId]; an unknown id is a failure.
  Future<Either<Failure, PropertyBookingsEntity>> getBookings(
    String propertyId,
  );

  /// The settings of [propertyId]; an unknown id is a failure.
  Future<Either<Failure, PropertySettingsEntity>> getSettings(
    String propertyId,
  );

  /// Saves the settings and returns them as stored.
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  });

  /// The add-property draft; a new one holds the source's defaults.
  Future<Either<Failure, AddPropertyDraftEntity>> getAddPropertyDraft();

  Future<Either<Failure, void>> saveAddPropertyDetails(
    SaveAddPropertyDetailsParamsEntity details,
  );

  Future<Either<Failure, void>> saveAddPropertyChannels(
    List<BookingChannel> channels,
  );

  /// Turns the draft into a property with [terms], clears the draft, and
  /// returns the new property's id.
  Future<Either<Failure, String>> publishProperty(PropertyTermsEntity terms);
}
