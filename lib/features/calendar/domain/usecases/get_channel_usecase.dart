import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

final class GetChannelUsecase
    implements
        Usecase<
          Future<Either<Failure, ChannelEntity>>,
          GetChannelParamsEntity
        > {
  const GetChannelUsecase(this._repository);

  final ChannelsRepository _repository;

  @override
  Future<Either<Failure, ChannelEntity>> call(GetChannelParamsEntity params) {
    return _repository.getChannel(params.channelId);
  }
}
