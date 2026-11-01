import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/publish_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_channels_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';

part 'add_property_event.dart';
part 'add_property_state.dart';

/// One step of «Добавить квартиру». Each step screen creates its own
/// instance; the draft that connects the steps is kept by the source.
///
/// A step loads the draft with [AddPropertyStarted] to prefill, then sends
/// its own submit event.
final class AddPropertyBloc extends Bloc<AddPropertyEvent, AddPropertyState> {
  AddPropertyBloc({
    required this._getDraft,
    required this._saveDetails,
    required this._saveChannels,
    required this._publish,
  }) : super(const AddPropertyState()) {
    on<AddPropertyStarted>(_onStarted, transformer: restartable());
    on<AddPropertyFieldEdited>(_onFieldEdited);
    on<AddPropertyDetailsSubmitted>(
      _onDetailsSubmitted,
      transformer: droppable(),
    );
    on<AddPropertyChannelsSubmitted>(
      _onChannelsSubmitted,
      transformer: droppable(),
    );
    on<AddPropertyTermsSubmitted>(_onTermsSubmitted, transformer: droppable());
  }

  final GetAddPropertyDraftUsecase _getDraft;
  final SaveAddPropertyDetailsUsecase _saveDetails;
  final SaveAddPropertyChannelsUsecase _saveChannels;
  final PublishPropertyUsecase _publish;

  Future<void> _onStarted(
    AddPropertyStarted event,
    Emitter<AddPropertyState> emit,
  ) async {
    emit(
      state.copyWith(
        draftStatus: RequestStatus.loading,
        resetDraftFailure: true,
      ),
    );

    final Either<Failure, AddPropertyDraftEntity> result = await _getDraft(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, AddPropertyDraftEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            draftStatus: RequestStatus.failure,
            draftFailure: failure,
          ),
        );
      case Right<Failure, AddPropertyDraftEntity>(
        value: final AddPropertyDraftEntity draft,
      ):
        emit(state.copyWith(draftStatus: RequestStatus.success, draft: draft));
    }
  }

  /// Hides the server error of the edited field and the general failure.
  void _onFieldEdited(
    AddPropertyFieldEdited event,
    Emitter<AddPropertyState> emit,
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

  Future<void> _onDetailsSubmitted(
    AddPropertyDetailsSubmitted event,
    Emitter<AddPropertyState> emit,
  ) {
    return _submit<void>(emit, () => _saveDetails(event.params));
  }

  Future<void> _onChannelsSubmitted(
    AddPropertyChannelsSubmitted event,
    Emitter<AddPropertyState> emit,
  ) {
    return _submit<void>(emit, () => _saveChannels(event.params));
  }

  /// Publishes once: after success the screen leaves the flow.
  Future<void> _onTermsSubmitted(
    AddPropertyTermsSubmitted event,
    Emitter<AddPropertyState> emit,
  ) {
    if (state.publishedPropertyId != null) {
      return Future<void>.value();
    }
    return _submit<String>(
      emit,
      () => _publish(event.params),
      onSuccess: (String propertyId) =>
          state.copyWith(publishedPropertyId: propertyId),
    );
  }

  /// Runs one submit; another submit while it runs is ignored.
  ///
  /// A [ValidationFailure] with field errors goes to
  /// [AddPropertyState.fieldErrors]; any other failure to
  /// [AddPropertyState.submitFailure].
  Future<void> _submit<T>(
    Emitter<AddPropertyState> emit,
    Future<Either<Failure, T>> Function() run, {
    AddPropertyState Function(T value)? onSuccess,
  }) async {
    if (state.submitStatus.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        submitStatus: RequestStatus.loading,
        resetSubmitFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, T> result = await run();
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, T>(value: final ValidationFailure failure)
          when failure.fieldErrors.isNotEmpty:
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            fieldErrors: Map<String, String>.unmodifiable(failure.fieldErrors),
          ),
        );
      case Left<Failure, T>(value: final Failure failure):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            submitFailure: failure,
          ),
        );
      case Right<Failure, T>(value: final T value):
        final AddPropertyState next = onSuccess?.call(value) ?? state;
        emit(next.copyWith(submitStatus: RequestStatus.success));
    }
  }
}
