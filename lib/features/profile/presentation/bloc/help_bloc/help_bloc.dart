import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';

part 'help_event.dart';
part 'help_state.dart';

/// «Помощь»: support contact, FAQ topics, and guides. The search field
/// filters the loaded content with `HelpCenterEntity.matching` in the UI.
final class HelpBloc extends Bloc<HelpEvent, HelpState> {
  HelpBloc({required this._getHelpCenter}) : super(const HelpState()) {
    on<HelpRequested>(_onRequested, transformer: restartable());
  }

  final GetHelpCenterUsecase _getHelpCenter;

  Future<void> _onRequested(
    HelpRequested event,
    Emitter<HelpState> emit,
  ) async {
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, HelpCenterEntity> result = await _getHelpCenter(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, HelpCenterEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, HelpCenterEntity>(
        value: final HelpCenterEntity helpCenter,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            helpCenter: helpCenter,
          ),
        );
    }
  }
}
