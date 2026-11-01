import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/search_booking_guests_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/save_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/search_booking_guests_usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';

part 'booking_draft_event.dart';
part 'booking_draft_state.dart';

/// Step 1 of a new booking, «Когда и где»: loads the apartments for the
/// picker and the saved draft for prefilling (with the source's today for
/// the default dates), searches earlier guests, and saves the form as the
/// draft that step 2 reads.
final class BookingDraftBloc
    extends Bloc<BookingDraftEvent, BookingDraftState> {
  BookingDraftBloc({
    required this._getProperties,
    required this._getDraft,
    required this._searchGuests,
    required this._saveDraft,
  }) : super(const BookingDraftState()) {
    on<BookingDraftStarted>(_onStarted, transformer: restartable());
    on<BookingDraftGuestSearched>(
      _onGuestSearched,
      transformer: debounceRestartable(guestSearchDebounce),
    );
    on<BookingDraftFieldEdited>(_onFieldEdited);
    on<BookingDraftSubmitted>(_onSubmitted, transformer: droppable());
  }

  static const Duration guestSearchDebounce = Duration(milliseconds: 300);

  /// Fields shown on the screen. An error keyed by anything else would be
  /// invisible, so it is also reported as [BookingDraftState.submitFailure].
  static const Set<String> _displayedFields = <String>{
    BookingFields.property,
    BookingFields.checkIn,
    BookingFields.checkOut,
    BookingFields.firstName,
    BookingFields.lastName,
    BookingFields.phone,
  };

  final GetPropertiesUsecase _getProperties;
  final GetBookingDraftUsecase _getDraft;
  final SearchBookingGuestsUsecase _searchGuests;
  final SaveBookingDraftUsecase _saveDraft;

  Future<void> _onStarted(
    BookingDraftStarted event,
    Emitter<BookingDraftState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final (
      Either<Failure, List<PropertyEntity>> propertiesResult,
      Either<Failure, CurrentBookingDraftEntity> draftResult,
    ) = await (
      _getProperties(const NoParams()),
      _getDraft(const NoParams()),
    ).wait;
    if (emit.isDone) {
      return;
    }
    switch ((propertiesResult, draftResult)) {
      case (
        Left<Failure, List<PropertyEntity>>(value: final Failure failure),
        _,
      ):
      case (
        _,
        Left<Failure, CurrentBookingDraftEntity>(value: final Failure failure),
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case (
        Right<Failure, List<PropertyEntity>>(
          value: final List<PropertyEntity> properties,
        ),
        Right<Failure, CurrentBookingDraftEntity>(
          value: CurrentBookingDraftEntity(
            :final BookingDraftEntity? draft,
            :final DateTime today,
          ),
        ),
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            properties: List<PropertyEntity>.unmodifiable(properties),
            draft: draft,
            resetDraft: draft == null,
            today: today,
          ),
        );
    }
  }

  /// Latest query wins: a newer search cancels the running one.
  Future<void> _onGuestSearched(
    BookingDraftGuestSearched event,
    Emitter<BookingDraftState> emit,
  ) async {
    final String query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          guestQuery: '',
          guestSearchStatus: RequestStatus.initial,
          guests: const <BookingGuestEntity>[],
          resetGuestSearchFailure: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        guestQuery: query,
        guestSearchStatus: RequestStatus.loading,
        resetGuestSearchFailure: true,
      ),
    );

    final Either<Failure, List<BookingGuestEntity>> result =
        await _searchGuests(SearchBookingGuestsParamsEntity(query: query));
    if (emit.isDone || state.guestQuery != query) {
      return;
    }
    switch (result) {
      case Left<Failure, List<BookingGuestEntity>>(
        value: final Failure failure,
      ):
        emit(
          state.copyWith(
            guestSearchStatus: RequestStatus.failure,
            guests: const <BookingGuestEntity>[],
            guestSearchFailure: failure,
          ),
        );
      case Right<Failure, List<BookingGuestEntity>>(
        value: final List<BookingGuestEntity> guests,
      ):
        emit(
          state.copyWith(
            guestSearchStatus: RequestStatus.success,
            guests: List<BookingGuestEntity>.unmodifiable(guests),
          ),
        );
    }
  }

  /// Hides the server error of the edited field and the general failure.
  void _onFieldEdited(
    BookingDraftFieldEdited event,
    Emitter<BookingDraftState> emit,
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

  /// Saving again is allowed after a success: the host may come back from
  /// step 2 and change the form.
  Future<void> _onSubmitted(
    BookingDraftSubmitted event,
    Emitter<BookingDraftState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: RequestStatus.loading,
        resetSubmitFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, BookingDraftEntity> result = await _saveDraft(
      event.params,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, BookingDraftEntity>(
            value: final ValidationFailure failure,
          )
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
      case Left<Failure, BookingDraftEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            submitFailure: failure,
          ),
        );
      case Right<Failure, BookingDraftEntity>(
        value: final BookingDraftEntity draft,
      ):
        emit(
          state.copyWith(submitStatus: RequestStatus.success, draft: draft),
        );
    }
  }
}
