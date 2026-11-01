import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/entity/home_stay_entity.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this._getHomeOverview}) : super(const HomeState()) {
    // Latest wins: a refresh replaces a load that is still running.
    on<HomeOverviewRequested>(
      _onOverviewRequested,
      transformer: restartable(),
    );
    on<HomeScopeSelected>(_onScopeSelected);
  }

  final GetHomeOverviewUsecase _getHomeOverview;

  /// Keeps the shown overview while loading, so a refresh does not blank
  /// the screen; a failed refresh keeps it too.
  Future<void> _onOverviewRequested(
    HomeOverviewRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, HomeOverviewEntity> result = await _getHomeOverview(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, HomeOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, HomeOverviewEntity>(
        value: final HomeOverviewEntity overview,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, overview: overview),
        );
    }
  }

  void _onScopeSelected(HomeScopeSelected event, Emitter<HomeState> emit) {
    emit(state.copyWith(scope: event.scope));
  }
}
