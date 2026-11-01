import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/data/sources/local/home_mock_local.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/repository/home_repository.dart';

/// Reads the overview from [HomeMockLocal], which already returns entities.
final class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({required this._local});

  final HomeMockLocal _local;

  @override
  Future<Either<Failure, HomeOverviewEntity>> getOverview() {
    return _local.loadOverview();
  }
}
