import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';

part 'booking_create_event.dart';
part 'booking_create_state.dart';

/// Step 2 of a new booking, «Цена и источник»: loads the draft saved on
/// step 1 with its quote and availability, and creates the booking.
final class BookingCreateBloc
    extends Bloc<BookingCreateEvent, BookingCreateState> {
  BookingCreateBloc({required this._getDraft, required this._createBooking})
    : super(const BookingCreateState()) {
    on<BookingCreateStarted>(_onStarted, transformer: restartable());
    on<BookingCreateFieldEdited>(_onFieldEdited);
    on<BookingCreateSubmitted>(_onSubmitted, transformer: droppable());
  }

  /// Fields shown on the screen. An error keyed by anything else would be
  /// invisible, so it is also reported as [BookingCreateState.submitFailure].
  static const Set<String> _displayedFields = <String>{
    BookingFields.totalPrice,
    BookingFields.deposit,
    BookingFields.source,
  };

  final GetBookingDraftUsecase _getDraft;
  final CreateBookingUsecase _createBooking;

  Future<void> _onStarted(
    BookingCreateStarted event,
    Emitter<BookingCreateState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, CurrentBookingDraftEntity> result = await _getDraft(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, CurrentBookingDraftEntity>(
        value: final Failure failure,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, CurrentBookingDraftEntity>(
        value: CurrentBookingDraftEntity(:final BookingDraftEntity? draft),
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            draft: draft,
            resetDraft: draft == null,
          ),
        );
    }
  }

  /// Hides the server error of the edited field and the general failure.
  void _onFieldEdited(
    BookingCreateFieldEdited event,
    Emitter<BookingCreateState> emit,
  ) {
    final bool hasFieldError = state.fieldErrors.containsKey(event.field);
    if (!hasFieldError &&
        state.submitFailure == null &&
        !state.submitStatus.isFailure) {
      return;
    }
    final Map<String, String> fieldErrors = hasFieldError
        ? Map<String, String>.unmodifiable(
            Map<String, String>.of(state.fieldErrors)..remove(event.field),
          )
        : state.fieldErrors;
    emit(
      state.copyWith(
        submitStatus: state.submitStatus.isFailure
            ? RequestStatus.initial
            : null,
        resetSubmitFailure: true,
        fieldErrors: fieldErrors,
      ),
    );
  }

  Future<void> _onSubmitted(
    BookingCreateSubmitted event,
    Emitter<BookingCreateState> emit,
  ) async {
    // The draft is consumed by a success; the screen then leaves.
    if (state.submitStatus.isLoading || state.submitStatus.isSuccess) {
      return;
    }
    emit(
      state.copyWith(
        submitStatus: RequestStatus.loading,
        resetSubmitFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, String> result = await _createBooking(event.params);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, String>(value: final ValidationFailure failure)
          when failure.fieldErrors.isNotEmpty:
        final bool isDisplayed = failure.fieldErrors.keys.any(
          _displayedFields.contains,
        );
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            fieldErrors: Map<String, String>.unmodifiable(failure.fieldErrors),
            submitFailure: isDisplayed ? null : failure,
          ),
        );
      case Left<Failure, String>(value: final Failure failure):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            submitFailure: failure,
          ),
        );
      case Right<Failure, String>(value: final String bookingId):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.success,
            createdBookingId: bookingId,
          ),
        );
    }
  }
}
