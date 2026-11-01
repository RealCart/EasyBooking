import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_directory_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';

part 'guests_event.dart';
part 'guests_state.dart';

/// The «Гости» and «Договоры» tabs of «Гости и договоры».
///
/// The source does the search, so every query is a request. Latest wins
/// across both events: each load takes a new version, and a result whose
/// version is no longer the newest is dropped.
final class GuestsBloc extends Bloc<GuestsEvent, GuestsState> {
  GuestsBloc({required this._getDirectory}) : super(const GuestsState()) {
    on<GuestsRequested>(_onRequested, transformer: restartable());
    on<GuestsQueryChanged>(
      _onQueryChanged,
      transformer: debounceRestartable(queryDebounce),
    );
  }

  /// How long typing must pause before the search runs.
  static const Duration queryDebounce = Duration(milliseconds: 300);

  final GetGuestDirectoryUsecase _getDirectory;

  int _version = 0;

  Future<void> _onRequested(
    GuestsRequested event,
    Emitter<GuestsState> emit,
  ) {
    return _load(state.query, emit);
  }

  Future<void> _onQueryChanged(
    GuestsQueryChanged event,
    Emitter<GuestsState> emit,
  ) async {
    final String query = event.query.trim();
    // The newest load already asks for this query.
    if (query == state.query &&
        (state.loadStatus.isLoading || state.loadStatus.isSuccess)) {
      return;
    }
    await _load(query, emit);
  }

  /// Keeps the shown result while loading and after a failure.
  Future<void> _load(String query, Emitter<GuestsState> emit) async {
    final int version = ++_version;
    emit(
      state.copyWith(
        query: query,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, GuestDirectoryEntity> result = await _getDirectory(
      GetGuestDirectoryParamsEntity(query: query),
    );
    if (emit.isDone || version != _version) {
      return;
    }
    switch (result) {
      case Left<Failure, GuestDirectoryEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, GuestDirectoryEntity>(
        value: final GuestDirectoryEntity directory,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            directory: directory,
          ),
        );
    }
  }
}
