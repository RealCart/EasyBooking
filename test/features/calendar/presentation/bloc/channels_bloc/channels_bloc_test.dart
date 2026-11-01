import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channels_bloc/channels_bloc.dart';

import '../../../../../helpers/fake_channels_repository.dart';

final class _Subject {
  _Subject() {
    bloc = ChannelsBloc(getChannels: GetChannelsUsecase(repository));
    final StreamSubscription<ChannelsState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeChannelsRepository repository = FakeChannelsRepository();
  late final ChannelsBloc bloc;
  final List<ChannelsState> states = <ChannelsState>[];

  Future<void> request() async {
    bloc.add(const ChannelsRequested());
    await pumpEventQueue();
  }
}

ChannelsOverviewEntity _overviewOf(List<ChannelEntity> channels) {
  return ChannelsOverviewEntity(
    channels: channels,
    checkedAt: channelsTestCheckedAt,
    receivedAt: channelsTestReceivedAt,
  );
}

void main() {
  group('ChannelsBloc', () {
    test('starts with nothing loaded', () {
      expect(_Subject().bloc.state, const ChannelsState());
    });

    test('a load emits loading, then the channels', () async {
      final _Subject subject = _Subject();

      await subject.request();

      expect(subject.repository.channelsCount, 1);
      expect(subject.states, <ChannelsState>[
        const ChannelsState(loadStatus: RequestStatus.loading),
        ChannelsState(
          loadStatus: RequestStatus.success,
          overview: testChannelsOverview(),
        ),
      ]);
    });

    test('a failure is reported, then cleared by a retry', () async {
      final _Subject subject = _Subject();
      subject.repository.channelsResult =
          const Left<Failure, ChannelsOverviewEntity>(ConnectionFailure());

      await subject.request();

      expect(subject.states, const <ChannelsState>[
        ChannelsState(loadStatus: RequestStatus.loading),
        ChannelsState(
          loadStatus: RequestStatus.failure,
          loadFailure: ConnectionFailure(),
        ),
      ]);

      subject.repository.channelsResult =
          Right<Failure, ChannelsOverviewEntity>(testChannelsOverview());
      await subject.request();

      expect(
        subject.states[2],
        const ChannelsState(loadStatus: RequestStatus.loading),
      );
      expect(subject.bloc.state.loadFailure, isNull);
      expect(subject.bloc.state.overview, testChannelsOverview());
    });

    test(
      'a reload keeps the channels while it runs and when it fails',
      () async {
        final _Subject subject = _Subject();
        await subject.request();
        subject.repository.holdChannels = true;

        await subject.request();

        expect(subject.bloc.state.loadStatus, RequestStatus.loading);
        expect(subject.bloc.state.overview, testChannelsOverview());

        subject.repository.heldChannels.single.complete(
          const Left<Failure, ChannelsOverviewEntity>(TimeoutFailure()),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.loadFailure, const TimeoutFailure());
        expect(subject.bloc.state.overview, testChannelsOverview());
      },
    );

    test('a stale load does not replace a newer one', () async {
      final _Subject subject = _Subject();
      subject.repository.holdChannels = true;
      await subject.request();
      await subject.request();
      final ChannelsOverviewEntity older = _overviewOf(<ChannelEntity>[
        testAirbnbChannel(),
      ]);
      final ChannelsOverviewEntity newer = _overviewOf(<ChannelEntity>[
        testAirbnbChannel(isRepaired: true),
      ]);

      subject.repository.heldChannels[1].complete(
        Right<Failure, ChannelsOverviewEntity>(newer),
      );
      await pumpEventQueue();
      subject.repository.heldChannels[0].complete(
        Right<Failure, ChannelsOverviewEntity>(older),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.overview, newer);
      expect(
        subject.states.map((ChannelsState s) => s.overview),
        isNot(contains(older)),
      );
    });

    test('channels arriving after close are dropped without errors', () async {
      final _Subject subject = _Subject();
      subject.repository.holdChannels = true;
      await subject.request();
      final int statesBefore = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldChannels.single.complete(
        Right<Failure, ChannelsOverviewEntity>(testChannelsOverview()),
      );
      await pumpEventQueue();

      expect(subject.states.length, statesBefore);
      expect(subject.bloc.state.overview, isNull);
    });
  });
}
