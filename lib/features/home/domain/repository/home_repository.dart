import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';

abstract interface class HomeRepository {
  /// Today's stays, tasks, and calendar sync status. Served by a mock
  /// source until the home API exists.
  Future<Either<Failure, HomeOverviewEntity>> getOverview();
}
