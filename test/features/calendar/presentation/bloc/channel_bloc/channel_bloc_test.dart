import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channel_bloc/channel_bloc.dart';

import '../../../../../helpers/fake_channels_repository.dart';

final class _Subject {
  _Subject() {
    bloc = ChannelBloc(
      getChannel: GetChannelUsecase(repository),
      syncChannel: SyncChannelUsecase(repository),
      disconnectChannel: DisconnectChannelUsecase(repository),
    );
    final StreamSubscription<ChannelState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeChannelsRepository repository = FakeChannelsRepository();
  late final ChannelBloc bloc;
  final List<ChannelState> states = <ChannelState>[];

  Future<void> add(ChannelEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads Airbnb and forgets the states of the load.
  Future<void> load() async {
    await add(const ChannelRequested('airbnb'));
    states.clear();
  }
}

final ChannelState _loaded = ChannelState(
  channelId: 'airbnb',
  loadStatus: RequestStatus.success,
  channel: testAirbnbChannel(),
);

void main() {
  group('ChannelBloc', () {
    test('starts with nothing loaded and not busy', () {
      final ChannelState state = _Subject().bloc.state;

      expect(state, const ChannelState());
      expect(state.isBusy, isFalse);
    });

    test('a load forwards the id and emits the channel', () async {
      final _Subject subject = _Subject();

      await subject.add(const ChannelRequested('airbnb'));

      expect(subject.repository.channelRequests, <String>['airbnb']);
      expect(subject.states, <ChannelState>[
        const ChannelState(
          channelId: 'airbnb',
          loadStatus: RequestStatus.loading,
        ),
        _loaded,
      ]);
    });

    test(
      'a failed load keeps the id, and a retry clears the failure',
      () async {
        final _Subject subject = _Subject();
        subject.repository.channelResult = const Left<Failure, ChannelEntity>(
          ConnectionFailure(),
        );

        await subject.add(const ChannelRequested('airbnb'));

        expect(
          subject.bloc.state,
          const ChannelState(
            channelId: 'airbnb',
            loadStatus: RequestStatus.failure,
            loadFailure: ConnectionFailure(),
          ),
        );

        subject.repository.channelResult = null;
        await subject.add(ChannelRequested(subject.bloc.state.channelId));

        expect(subject.states[2].loadFailure, isNull);
        expect(subject.bloc.state, _loaded);
      },
    );

    test('a stale load does not replace a newer one', () async {
      final _Subject subject = _Subject();
      subject.repository.holdChannel = true;
      await subject.add(const ChannelRequested('airbnb'));
      await subject.add(const ChannelRequested('booking-com'));

      subject.repository.heldChannel[1].complete(
        Right<Failure, ChannelEntity>(testBookingChannel()),
      );
      await pumpEventQueue();
      subject.repository.heldChannel[0].complete(
        Right<Failure, ChannelEntity>(testAirbnbChannel()),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.channel, testBookingChannel());
      expect(subject.bloc.state.channelId, 'booking-com');
    });

    test('sync and disconnect are ignored before the channel loads', () async {
      final _Subject subject = _Subject();

      await subject.add(const ChannelSyncRequested());
      await subject.add(const ChannelDisconnectRequested());

      expect(subject.repository.syncRequests, isEmpty);
      expect(subject.repository.disconnectRequests, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('a sync replaces the channel with the synced one', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const ChannelSyncRequested());

      expect(subject.repository.syncRequests, <String>['airbnb']);
      expect(subject.states, <ChannelState>[
        _loaded.copyWith(syncStatus: RequestStatus.loading),
        _loaded.copyWith(
          syncStatus: RequestStatus.success,
          channel: testAirbnbChannel(isRepaired: true),
        ),
      ]);
    });

    test('a sync failure is kept, and the next sync clears it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.syncResult = const Left<Failure, ChannelEntity>(
        ServerFailure(statusCode: 409),
      );

      await subject.add(const ChannelSyncRequested());

      expect(subject.bloc.state.syncStatus, RequestStatus.failure);
      expect(
        subject.bloc.state.syncFailure,
        const ServerFailure(statusCode: 409),
      );
      expect(subject.bloc.state.channel, testAirbnbChannel());

      subject.repository.syncResult = null;
      await subject.add(const ChannelSyncRequested());

      expect(subject.states[2].syncStatus, RequestStatus.loading);
      expect(subject.states[2].syncFailure, isNull);
      expect(subject.bloc.state.syncStatus, RequestStatus.success);
    });

    test(
      'while a sync runs, it is busy and both actions are ignored',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.holdSync = true;

        await subject.add(const ChannelSyncRequested());
        expect(subject.bloc.state.isBusy, isTrue);

        await subject.add(const ChannelSyncRequested());
        await subject.add(const ChannelDisconnectRequested());

        expect(subject.repository.syncRequests, hasLength(1));
        expect(subject.repository.disconnectRequests, isEmpty);
        expect(subject.bloc.state.disconnectStatus, RequestStatus.initial);

        subject.repository.heldSyncs.single.complete(
          Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true)),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.isBusy, isFalse);
        expect(subject.states, hasLength(2));
      },
    );

    test(
      'while a disconnect runs, it is busy and both actions are ignored',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.holdDisconnect = true;

        await subject.add(const ChannelDisconnectRequested());
        expect(subject.bloc.state.isBusy, isTrue);

        await subject.add(const ChannelDisconnectRequested());
        await subject.add(const ChannelSyncRequested());

        expect(subject.repository.disconnectRequests, hasLength(1));
        expect(subject.repository.syncRequests, isEmpty);

        subject.repository.heldDisconnects.single.complete(
          const Right<Failure, void>(null),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.isBusy, isFalse);
      },
    );

    test('a disconnect succeeds without reloading the channel', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const ChannelDisconnectRequested());

      expect(subject.repository.disconnectRequests, <String>['airbnb']);
      expect(subject.repository.channelRequests, hasLength(1));
      expect(subject.states, <ChannelState>[
        _loaded.copyWith(disconnectStatus: RequestStatus.loading),
        _loaded.copyWith(disconnectStatus: RequestStatus.success),
      ]);
    });

    test('a disconnect failure is kept, and the next try clears it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.disconnectResult = const Left<Failure, void>(
        TimeoutFailure(),
      );

      await subject.add(const ChannelDisconnectRequested());

      expect(subject.bloc.state.disconnectStatus, RequestStatus.failure);
      expect(subject.bloc.state.disconnectFailure, const TimeoutFailure());

      subject.repository.disconnectResult = const Right<Failure, void>(null);
      await subject.add(const ChannelDisconnectRequested());

      expect(subject.states[2].disconnectFailure, isNull);
      expect(subject.bloc.state.disconnectStatus, RequestStatus.success);
    });

    test('a sync finishing after close is dropped without errors', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdSync = true;
      await subject.add(const ChannelSyncRequested());

      await subject.bloc.close();
      subject.repository.heldSyncs.single.complete(
        Right<Failure, ChannelEntity>(testAirbnbChannel(isRepaired: true)),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
      expect(subject.bloc.state.channel, testAirbnbChannel());
    });
  });
}
