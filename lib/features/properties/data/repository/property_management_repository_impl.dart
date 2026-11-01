import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// Delegates to [PropertyManagementMockLocal], which already returns
/// entities and keeps the draft between the add-property steps.
final class PropertyManagementRepositoryImpl
    implements PropertyManagementRepository {
  const PropertyManagementRepositoryImpl({required this._local});

  final PropertyManagementMockLocal _local;

  @override
  Future<Either<Failure, PropertyBookingsEntity>> getBookings(
    String propertyId,
  ) {
    return _local.loadBookings(propertyId);
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> getSettings(
    String propertyId,
  ) {
    return _local.loadSettings(propertyId);
  }

  @override
  Future<Either<Failure, PropertySettingsEntity>> saveSettings({
    required String propertyId,
    required bool acceptsBookings,
  }) {
    return _local.saveSettings(
      propertyId: propertyId,
      acceptsBookings: acceptsBookings,
    );
  }

  @override
  Future<Either<Failure, AddPropertyDraftEntity>> getAddPropertyDraft() {
    return _local.loadDraft();
  }

  @override
  Future<Either<Failure, void>> saveAddPropertyDetails(
    SaveAddPropertyDetailsParamsEntity details,
  ) {
    return _local.saveDraftDetails(details);
  }

  @override
  Future<Either<Failure, void>> saveAddPropertyChannels(
    List<BookingChannel> channels,
  ) {
    return _local.saveDraftChannels(channels);
  }

  @override
  Future<Either<Failure, String>> publishProperty(PropertyTermsEntity terms) {
    return _local.publishDraft(terms);
  }
}
