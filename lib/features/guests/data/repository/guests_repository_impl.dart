import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/data/sources/local/guests_mock_local.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';

/// Delegates to [GuestsMockLocal], which already returns entities.
final class GuestsRepositoryImpl implements GuestsRepository {
  const GuestsRepositoryImpl({required this._local});

  final GuestsMockLocal _local;

  @override
  Future<Either<Failure, GuestDirectoryEntity>> getDirectory(String query) {
    return _local.loadDirectory(query);
  }

  @override
  Future<Either<Failure, GuestEntity>> getGuest(String id) {
    return _local.loadGuest(id);
  }

  @override
  Future<Either<Failure, String>> createContract(String guestId) {
    return _local.createContract(guestId);
  }
}
