import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/help_bloc/help_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [HelpBloc] over a [FakeProfileRepository] that records its states.
final class _Subject {
  _Subject() {
    bloc = HelpBloc(getHelpCenter: GetHelpCenterUsecase(repository));
    final StreamSubscription<HelpState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final HelpBloc bloc;
  final List<HelpState> states = <HelpState>[];

  Future<void> add(HelpEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('HelpBloc', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const HelpState());
    });

    test('a load emits loading, then the help center', () async {
      final _Subject subject = _Subject();

      await subject.add(const HelpRequested());

      expect(subject.states, const <HelpState>[
        HelpState(loadStatus: RequestStatus.loading),
        HelpState(
          loadStatus: RequestStatus.success,
          helpCenter: testHelpCenter,
        ),
      ]);
    });

    test('a failed load emits the failure; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.helpResult = const Left<Failure, HelpCenterEntity>(
        _failure,
      );

      await subject.add(const HelpRequested());

      expect(
        subject.bloc.state,
        const HelpState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      );

      subject.repository.helpResult = const Right<Failure, HelpCenterEntity>(
        testHelpCenter,
      );
      subject.states.clear();
      await subject.add(const HelpRequested());

      expect(subject.states, const <HelpState>[
        HelpState(loadStatus: RequestStatus.loading),
        HelpState(
          loadStatus: RequestStatus.success,
          helpCenter: testHelpCenter,
        ),
      ]);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdHelp = true;
      await subject.add(const HelpRequested());
      await subject.add(const HelpRequested());

      subject.repository.heldHelp[1].complete(
        const Right<Failure, HelpCenterEntity>(testHelpCenter),
      );
      await pumpEventQueue();
      subject.repository.heldHelp[0].complete(
        const Left<Failure, HelpCenterEntity>(_failure),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.helpCenter, testHelpCenter);
      expect(subject.bloc.state.loadFailure, isNull);
    });

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdHelp = true;
      await subject.add(const HelpRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldHelp.single.complete(
        const Right<Failure, HelpCenterEntity>(testHelpCenter),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });
}
