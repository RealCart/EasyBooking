import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_day_usecase.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

final class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({required this._getCalendarDay}) : super(const CalendarState()) {
    // Every event loads a day, so one restartable handler lets only the
    // latest selection land, whichever event started it.
    on<CalendarEvent>(_onChanged, transformer: restartable());
  }

  final GetCalendarDayUsecase _getCalendarDay;

  Future<void> _onChanged(
    CalendarEvent event,
    Emitter<CalendarState> emit,
  ) async {
    final DateTime? date = switch (event) {
      CalendarDaySelected(:final DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
      ),
      CalendarRequested() || CalendarScopeSelected() => state.selectedDate,
    };
    final bool favoritesOnly = switch (event) {
      CalendarScopeSelected(:final bool favoritesOnly) => favoritesOnly,
      CalendarRequested() || CalendarDaySelected() => state.favoritesOnly,
    };
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        selectedDate: date,
        favoritesOnly: favoritesOnly,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, CalendarDayEntity> result = await _getCalendarDay(
      CalendarDayParamsEntity(date: date, favoritesOnly: favoritesOnly),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, CalendarDayEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, CalendarDayEntity>(
        value: final CalendarDayEntity day,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            day: day,
            selectedDate: day.date,
          ),
        );
    }
  }
}
