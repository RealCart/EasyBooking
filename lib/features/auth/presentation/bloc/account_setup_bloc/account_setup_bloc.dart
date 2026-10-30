import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';

part 'account_setup_event.dart';
part 'account_setup_state.dart';

final class AccountSetupBloc
    extends Bloc<AccountSetupEvent, AccountSetupState> {
  AccountSetupBloc({required this._createAccount, required this._signOut})
    : super(const AccountSetupState()) {
    on<AccountFirstNameChanged>(_onFirstNameChanged);
    on<AccountLastNameChanged>(_onLastNameChanged);
    on<AccountEmailChanged>(_onEmailChanged);
    on<AccountTeamNameChanged>(_onTeamNameChanged);
    on<AccountCitySelected>(_onCitySelected);
    on<AccountSetupSubmitted>(_onSubmitted, transformer: droppable());
    on<AccountSetupCancelled>(_onCancelled, transformer: droppable());
  }

  /// Fields shown on the screen. A server error keyed by anything else (for
  /// example `timeZone`) would be invisible, so it is also reported as
  /// [AccountSetupState.failure].
  static const Set<String> _displayedFields = <String>{
    AccountFields.firstName,
    AccountFields.lastName,
    AccountFields.email,
    AccountFields.teamName,
    AccountFields.city,
  };

  final CreateAccountUsecase _createAccount;
  final SignOutUsecase _signOut;

  void _onFirstNameChanged(
    AccountFirstNameChanged event,
    Emitter<AccountSetupState> emit,
  ) {
    _applyFieldChange(
      emit,
      field: AccountFields.firstName,
      next: state.copyWith(firstName: event.firstName),
    );
  }

  void _onLastNameChanged(
    AccountLastNameChanged event,
    Emitter<AccountSetupState> emit,
  ) {
    _applyFieldChange(
      emit,
      field: AccountFields.lastName,
      next: state.copyWith(lastName: event.lastName),
    );
  }

  void _onEmailChanged(
    AccountEmailChanged event,
    Emitter<AccountSetupState> emit,
  ) {
    _applyFieldChange(
      emit,
      field: AccountFields.email,
      next: state.copyWith(email: event.email),
    );
  }

  void _onTeamNameChanged(
    AccountTeamNameChanged event,
    Emitter<AccountSetupState> emit,
  ) {
    _applyFieldChange(
      emit,
      field: AccountFields.teamName,
      next: state.copyWith(teamName: event.teamName),
    );
  }

  void _onCitySelected(
    AccountCitySelected event,
    Emitter<AccountSetupState> emit,
  ) {
    _applyFieldChange(
      emit,
      field: AccountFields.city,
      next: state.copyWith(city: event.city),
    );
  }

  /// Emits [next] without [field]'s error and without the general failure.
  void _applyFieldChange(
    Emitter<AccountSetupState> emit, {
    required String field,
    required AccountSetupState next,
  }) {
    if (next == state) {
      return;
    }
    final Map<String, String> fieldErrors = state.fieldErrors.containsKey(field)
        ? Map<String, String>.unmodifiable(
            Map<String, String>.of(state.fieldErrors)..remove(field),
          )
        : state.fieldErrors;
    emit(
      next.copyWith(
        status: state.status.isFailure ? RequestStatus.initial : null,
        resetFailure: true,
        fieldErrors: fieldErrors,
      ),
    );
  }

  Future<void> _onSubmitted(
    AccountSetupSubmitted event,
    Emitter<AccountSetupState> emit,
  ) async {
    // After success the router leaves the screen; never create twice.
    if (state.status.isLoading || state.status.isSuccess) {
      return;
    }
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        resetFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, void> result = await _createAccount(
      CreateAccountParams(
        firstName: state.firstName,
        lastName: state.lastName,
        email: state.email,
        teamName: state.teamName,
        city: state.city,
      ),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final ValidationFailure failure)
          when failure.fieldErrors.isNotEmpty:
        final bool isDisplayed = failure.fieldErrors.keys.any(
          _displayedFields.contains,
        );
        emit(
          state.copyWith(
            status: RequestStatus.failure,
            fieldErrors: Map<String, String>.unmodifiable(failure.fieldErrors),
            failure: isDisplayed ? null : failure,
          ),
        );
      case Left<Failure, void>(value: final Failure failure):
        emit(state.copyWith(status: RequestStatus.failure, failure: failure));
      case Right<Failure, void>():
        emit(state.copyWith(status: RequestStatus.success));
    }
  }

  Future<void> _onCancelled(
    AccountSetupCancelled event,
    Emitter<AccountSetupState> emit,
  ) async {
    // An orphaned create request would later complete account setup, possibly
    // on another user's session.
    if (state.status.isLoading) {
      return;
    }
    final Either<Failure, void> result = await _signOut(const NoParams());
    if (emit.isDone) {
      return;
    }
    // The session signs out in memory before the storage is cleared, so the
    // router leaves this screen even when clearing fails; report it anyway.
    if (result case Left<Failure, void>(value: final Failure failure)) {
      emit(state.copyWith(status: RequestStatus.failure, failure: failure));
    }
  }
}
