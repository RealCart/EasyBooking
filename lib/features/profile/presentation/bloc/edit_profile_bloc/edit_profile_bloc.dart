import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';

part 'edit_profile_event.dart';
part 'edit_profile_state.dart';

/// «Редактировать профиль»: loads the current details to fill the form and
/// saves the submitted form.
final class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  EditProfileBloc({
    required this._getProfileDetails,
    required this._updateProfile,
  }) : super(const EditProfileState()) {
    on<EditProfileStarted>(_onStarted, transformer: restartable());
    on<EditProfileFieldEdited>(_onFieldEdited);
    on<EditProfileSubmitted>(_onSubmitted, transformer: droppable());
  }

  /// Fields shown on the screen. A server error keyed by anything else
  /// would be invisible, so it is also reported as
  /// [EditProfileState.saveFailure].
  static const Set<String> _displayedFields = <String>{
    ProfileFields.firstName,
    ProfileFields.lastName,
    ProfileFields.email,
    ProfileFields.teamName,
    ProfileFields.city,
  };

  final GetProfileDetailsUsecase _getProfileDetails;
  final UpdateProfileUsecase _updateProfile;

  /// Bumped by every successful save, so a load that started earlier does
  /// not replace the saved details with older ones.
  int _saveCount = 0;

  Future<void> _onStarted(
    EditProfileStarted event,
    Emitter<EditProfileState> emit,
  ) async {
    final int saveCount = _saveCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, ProfileDetailsEntity> result =
        await _getProfileDetails(const NoParams());
    if (emit.isDone) {
      return;
    }
    if (saveCount != _saveCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, ProfileDetailsEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, ProfileDetailsEntity>(
        value: final ProfileDetailsEntity details,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, details: details),
        );
    }
  }

  /// Hides the server error of the edited field and the general failure.
  void _onFieldEdited(
    EditProfileFieldEdited event,
    Emitter<EditProfileState> emit,
  ) {
    final bool hasFieldError = state.fieldErrors.containsKey(event.field);
    if (!hasFieldError &&
        state.saveFailure == null &&
        !state.saveStatus.isFailure) {
      return;
    }
    final Map<String, String> fieldErrors = hasFieldError
        ? Map<String, String>.unmodifiable(
            Map<String, String>.of(state.fieldErrors)..remove(event.field),
          )
        : state.fieldErrors;
    emit(
      state.copyWith(
        saveStatus: state.saveStatus.isFailure ? RequestStatus.initial : null,
        resetSaveFailure: true,
        fieldErrors: fieldErrors,
      ),
    );
  }

  Future<void> _onSubmitted(
    EditProfileSubmitted event,
    Emitter<EditProfileState> emit,
  ) async {
    if (state.saveStatus.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        resetSaveFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, ProfileDetailsEntity> result = await _updateProfile(
      event.params,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ProfileDetailsEntity>(
            value: final ValidationFailure failure,
          )
          when failure.fieldErrors.isNotEmpty:
        final bool isDisplayed = failure.fieldErrors.keys.any(
          _displayedFields.contains,
        );
        emit(
          state.copyWith(
            saveStatus: RequestStatus.failure,
            fieldErrors: Map<String, String>.unmodifiable(failure.fieldErrors),
            saveFailure: isDisplayed ? null : failure,
          ),
        );
      case Left<Failure, ProfileDetailsEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            saveStatus: RequestStatus.failure,
            saveFailure: failure,
          ),
        );
      case Right<Failure, ProfileDetailsEntity>(
        value: final ProfileDetailsEntity details,
      ):
        _saveCount += 1;
        emit(
          state.copyWith(saveStatus: RequestStatus.success, details: details),
        );
    }
  }
}
