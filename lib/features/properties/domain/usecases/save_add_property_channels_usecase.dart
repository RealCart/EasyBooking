import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_channels_params_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// Saves the channels of step 2 to the draft. No channel is fine: they can
/// be connected later. A repeated channel is kept once, in first order.
final class SaveAddPropertyChannelsUsecase
    implements
        Usecase<
          Future<Either<Failure, void>>,
          SaveAddPropertyChannelsParamsEntity
        > {
  const SaveAddPropertyChannelsUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, void>> call(
    SaveAddPropertyChannelsParamsEntity params,
  ) {
    return _repository.saveAddPropertyChannels(
      List<BookingChannel>.unmodifiable(<BookingChannel>{...params.channels}),
    );
  }
}
