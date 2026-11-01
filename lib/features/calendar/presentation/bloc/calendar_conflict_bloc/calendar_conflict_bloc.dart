import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/resolve_calendar_conflict_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';

part 'calendar_conflict_event.dart';
part 'calendar_conflict_state.dart';

/// One conflict on «Конфликт календарей», and keeping one of its bookings.
final class CalendarConflictBloc
    extends Bloc<CalendarConflictEvent, CalendarConflictState> {
  CalendarConflictBloc({
    required this._getConflict,
    required this._resolveConflict,
  }) : super(const CalendarConflictState()) {
    on<CalendarConflictRequested>(_onRequested, transformer: restartable());
    on<CalendarConflictBookingKept>(
      _onBookingKept,
      transformer: droppable(),
    );
  }

  final GetCalendarConflictUsecase _getConflict;
  final ResolveCalendarConflictUsecase _resolveConflict;

  Future<void> _onRequested(
    CalendarConflictRequested event,
    Emitter<CalendarConflictState> emit,
  ) async {
    emit(
      state.copyWith(
        conflictId: event.conflictId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, CalendarConflictEntity> result = await _getConflict(
      GetCalendarConflictParamsEntity(conflictId: event.conflictId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, CalendarConflictEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, CalendarConflictEntity>(
        value: final CalendarConflictEntity conflict,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, conflict: conflict),
        );
    }
  }

  /// Ignored before the conflict loads and once it is resolved.
  Future<void> _onBookingKept(
    CalendarConflictBookingKept event,
    Emitter<CalendarConflictState> emit,
  ) async {
    final CalendarConflictEntity? conflict = state.conflict;
    if (conflict == null || conflict.isResolved) {
      return;
    }
    emit(
      state.copyWith(
        resolveStatus: RequestStatus.loading,
        keepingBookingId: event.bookingId,
        resetResolveFailure: true,
      ),
    );

    final Either<Failure, CalendarConflictEntity> result =
        await _resolveConflict(
          ResolveCalendarConflictParamsEntity(
            conflictId: conflict.id,
            keepBookingId: event.bookingId,
          ),
        );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, CalendarConflictEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            resolveStatus: RequestStatus.failure,
            resolveFailure: failure,
            resetKeepingBookingId: true,
          ),
        );
      case Right<Failure, CalendarConflictEntity>(
        value: final CalendarConflictEntity resolved,
      ):
        emit(
          state.copyWith(
            resolveStatus: RequestStatus.success,
            conflict: resolved,
            resetKeepingBookingId: true,
          ),
        );
    }
  }
}
