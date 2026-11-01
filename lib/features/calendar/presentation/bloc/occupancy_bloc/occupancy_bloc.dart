import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';

part 'occupancy_event.dart';
part 'occupancy_state.dart';

/// The week grid of «Занятость объектов».
final class OccupancyBloc extends Bloc<OccupancyEvent, OccupancyState> {
  OccupancyBloc({required this._getOccupancyWeek})
    : super(const OccupancyState()) {
    // Every event loads a week, so one restartable handler lets only the
    // latest selection land, whichever event started it.
    on<OccupancyEvent>(_onChanged, transformer: restartable());
  }

  final GetOccupancyWeekUsecase _getOccupancyWeek;

  Future<void> _onChanged(
    OccupancyEvent event,
    Emitter<OccupancyState> emit,
  ) async {
    final DateTime? weekStart = switch (event) {
      OccupancyWeekSelected(:final DateTime date) => date.startOfWeek,
      OccupancyCurrentWeekSelected() => null,
      OccupancyRequested() || OccupancyScopeSelected() => state.weekStart,
    };
    final bool favoritesOnly = switch (event) {
      OccupancyScopeSelected(:final bool favoritesOnly) => favoritesOnly,
      OccupancyRequested() ||
      OccupancyWeekSelected() ||
      OccupancyCurrentWeekSelected() => state.favoritesOnly,
    };
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        weekStart: weekStart,
        resetWeekStart: weekStart == null,
        favoritesOnly: favoritesOnly,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, OccupancyWeekEntity> result = await _getOccupancyWeek(
      OccupancyWeekParamsEntity(date: weekStart, favoritesOnly: favoritesOnly),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, OccupancyWeekEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, OccupancyWeekEntity>(
        value: final OccupancyWeekEntity week,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            week: week,
            weekStart: week.weekStart,
          ),
        );
    }
  }
}
