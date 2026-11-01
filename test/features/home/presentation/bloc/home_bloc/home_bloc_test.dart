import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';
import 'package:easy_booking/features/home/presentation/bloc/home_bloc/home_bloc.dart';

import '../../../../../helpers/fake_home_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [HomeBloc] over a [FakeHomeRepository] that records its states.
final class _Subject {
  _Subject() {
    bloc = HomeBloc(getHomeOverview: GetHomeOverviewUsecase(repository));
    final StreamSubscription<HomeState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeHomeRepository repository = FakeHomeRepository();
  late final HomeBloc bloc;
  final List<HomeState> states = <HomeState>[];

  Future<void> add(HomeEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads [overview] and forgets the states of that load.
  Future<void> loaded(HomeOverviewEntity overview) async {
    repository.overviewResult = Right<Failure, HomeOverviewEntity>(overview);
    await add(const HomeOverviewRequested());
    states.clear();
  }
}

void main() {
  group('HomeBloc', () {
    test('starts with nothing loaded and arrivals selected', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const HomeState());
      expect(subject.bloc.state.scope, HomeStayScope.arrivals);
      expect(subject.bloc.state.stays, isEmpty);
    });

    test('a load emits loading, then the overview', () async {
      final _Subject subject = _Subject();
      final HomeOverviewEntity overview = testHomeOverview();

      await subject.add(const HomeOverviewRequested());

      expect(subject.states, <HomeState>[
        const HomeState(loadStatus: RequestStatus.loading),
        HomeState(loadStatus: RequestStatus.success, overview: overview),
      ]);
      expect(subject.bloc.state.stays, overview.arrivals);
    });

    test('a failed load emits the failure without an overview', () async {
      final _Subject subject = _Subject();
      subject.repository.overviewResult =
          const Left<Failure, HomeOverviewEntity>(_failure);

      await subject.add(const HomeOverviewRequested());

      expect(subject.states, const <HomeState>[
        HomeState(loadStatus: RequestStatus.loading),
        HomeState(loadStatus: RequestStatus.failure, loadFailure: _failure),
      ]);
    });

    test('a retry clears the failure while it loads', () async {
      final _Subject subject = _Subject();
      subject.repository.overviewResult =
          const Left<Failure, HomeOverviewEntity>(_failure);
      await subject.add(const HomeOverviewRequested());
      subject.states.clear();
      subject.repository.overviewResult = Right<Failure, HomeOverviewEntity>(
        testHomeOverview(),
      );

      await subject.add(const HomeOverviewRequested());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.states.first.loadStatus, RequestStatus.loading);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.loadFailure, isNull);
    });

    test(
      'a refresh keeps the overview while loading and after failing',
      () async {
        final _Subject subject = _Subject();
        final HomeOverviewEntity overview = testHomeOverview();
        await subject.loaded(overview);
        subject.repository.overviewResult =
            const Left<Failure, HomeOverviewEntity>(_failure);

        await subject.add(const HomeOverviewRequested());

        expect(subject.states, <HomeState>[
          HomeState(loadStatus: RequestStatus.loading, overview: overview),
          HomeState(
            loadStatus: RequestStatus.failure,
            overview: overview,
            loadFailure: _failure,
          ),
        ]);
      },
    );

    test('a refresh replaces the overview', () async {
      final _Subject subject = _Subject();
      await subject.loaded(testHomeOverview());
      final HomeOverviewEntity refreshed = testHomeOverview(
        propertyName: 'Samal',
      );
      subject.repository.overviewResult = Right<Failure, HomeOverviewEntity>(
        refreshed,
      );

      await subject.add(const HomeOverviewRequested());

      expect(subject.bloc.state.overview, refreshed);
    });

    test('selecting a scope shows its stays and keeps the overview', () async {
      final _Subject subject = _Subject();
      final HomeOverviewEntity overview = testHomeOverview();
      await subject.loaded(overview);

      await subject.add(const HomeScopeSelected(HomeStayScope.departures));

      expect(subject.states, <HomeState>[
        HomeState(
          loadStatus: RequestStatus.success,
          overview: overview,
          scope: HomeStayScope.departures,
        ),
      ]);
      expect(subject.bloc.state.stays, overview.departures);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdOverview = true;
      final HomeOverviewEntity older = testHomeOverview(propertyName: 'Older');
      final HomeOverviewEntity newer = testHomeOverview(propertyName: 'Newer');

      await subject.add(const HomeOverviewRequested());
      await subject.add(const HomeOverviewRequested());
      subject.repository.heldOverviews[1].complete(
        Right<Failure, HomeOverviewEntity>(newer),
      );
      await pumpEventQueue();
      subject.repository.heldOverviews[0].complete(
        Right<Failure, HomeOverviewEntity>(older),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.overview, newer);
      expect(
        subject.states.where((HomeState state) => state.overview == older),
        isEmpty,
      );
    });

    test('a load that completes after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdOverview = true;
      await subject.add(const HomeOverviewRequested());
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldOverviews.single.complete(
        Right<Failure, HomeOverviewEntity>(testHomeOverview()),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.bloc.state.loadStatus, RequestStatus.loading);
    });
  });
}
