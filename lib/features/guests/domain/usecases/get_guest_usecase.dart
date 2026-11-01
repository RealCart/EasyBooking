import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';

final class GetGuestUsecase
    implements
        Usecase<Future<Either<Failure, GuestEntity>>, GetGuestParamsEntity> {
  const GetGuestUsecase(this._repository);

  final GuestsRepository _repository;

  @override
  Future<Either<Failure, GuestEntity>> call(GetGuestParamsEntity params) {
    return _repository.getGuest(params.guestId);
  }
}
