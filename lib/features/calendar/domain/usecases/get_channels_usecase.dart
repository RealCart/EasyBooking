import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

final class GetChannelsUsecase
    implements
        Usecase<Future<Either<Failure, ChannelsOverviewEntity>>, NoParams> {
  const GetChannelsUsecase(this._repository);

  final ChannelsRepository _repository;

  @override
  Future<Either<Failure, ChannelsOverviewEntity>> call(NoParams params) {
    return _repository.getChannels();
  }
}
