import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/team_bloc/team_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

const InviteTeamMemberParamsEntity _invite = InviteTeamMemberParamsEntity(
  firstName: 'Дана',
  lastName: 'Ахметова',
  phone: '700 555 12 34',
  role: ProfileRole.cleaner,
);

const TeamMemberEntity _invited = TeamMemberEntity(
  id: 'member-invited-1',
  firstName: 'Дана',
  lastName: 'Ахметова',
  phone: '+77005551234',
  role: ProfileRole.cleaner,
  propertyCount: 0,
  hasAllProperties: false,
  isCurrentUser: false,
  status: TeamMemberStatus.invited,
);

const List<TeamMemberEntity> _teamAfterInvite = <TeamMemberEntity>[
  ...testTeam,
  _invited,
];

const List<TeamMemberEntity> _teamAfterRemove = <TeamMemberEntity>[
  testOwner,
  testCleaner,
];

/// A [TeamBloc] over a [FakeProfileRepository] that records its states.
final class _Subject {
  _Subject() {
    repository
      ..inviteResult = const Right<Failure, List<TeamMemberEntity>>(
        _teamAfterInvite,
      )
      ..removeResult = const Right<Failure, List<TeamMemberEntity>>(
        _teamAfterRemove,
      );
    bloc = TeamBloc(
      getTeam: GetTeamUsecase(repository),
      inviteTeamMember: InviteTeamMemberUsecase(repository),
      removeTeamMember: RemoveTeamMemberUsecase(repository),
    );
    final StreamSubscription<TeamState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final TeamBloc bloc;
  final List<TeamState> states = <TeamState>[];

  Future<void> add(TeamEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads the team, then forgets the recorded states.
  Future<void> load() async {
    await add(const TeamRequested());
    states.clear();
  }
}

void main() {
  group('TeamBloc load', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const TeamState());
    });

    test('a load emits loading, then the members', () async {
      final _Subject subject = _Subject();

      await subject.add(const TeamRequested());

      expect(subject.states, const <TeamState>[
        TeamState(loadStatus: RequestStatus.loading),
        TeamState(loadStatus: RequestStatus.success, members: testTeam),
      ]);
      expect(
        () => subject.bloc.state.members.add(_invited),
        throwsUnsupportedError,
      );
    });

    test('a failed load emits the failure', () async {
      final _Subject subject = _Subject();
      subject.repository.teamResult =
          const Left<Failure, List<TeamMemberEntity>>(_failure);

      await subject.add(const TeamRequested());

      expect(subject.states, const <TeamState>[
        TeamState(loadStatus: RequestStatus.loading),
        TeamState(loadStatus: RequestStatus.failure, loadFailure: _failure),
      ]);
    });

    test('a failed refresh keeps the members and a retry clears it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.teamResult =
          const Left<Failure, List<TeamMemberEntity>>(_failure);
      await subject.add(const TeamRequested());

      expect(subject.bloc.state.members, testTeam);
      expect(subject.bloc.state.loadFailure, _failure);

      subject.repository.teamResult =
          const Right<Failure, List<TeamMemberEntity>>(testTeam);
      subject.states.clear();
      await subject.add(const TeamRequested());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdTeam = true;
      await subject.add(const TeamRequested());
      await subject.add(const TeamRequested());

      subject.repository.heldTeam[1].complete(
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      await pumpEventQueue();
      subject.repository.heldTeam[0].complete(
        const Right<Failure, List<TeamMemberEntity>>(_teamAfterRemove),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.members, testTeam);
    });

    test('a load that started before an invite keeps the new team', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdTeam = true;
      await subject.add(const TeamRequested());

      await subject.add(const TeamInviteSubmitted(_invite));
      subject.repository.heldTeam.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.members, _teamAfterInvite);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('a load that started before a removal keeps the new team', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdTeam = true;
      await subject.add(const TeamRequested());

      await subject.add(const TeamMemberRemoveRequested('member-aliya'));
      subject.repository.heldTeam.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.members, _teamAfterRemove);
    });

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdTeam = true;
      await subject.add(const TeamRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldTeam.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('TeamBloc invite', () {
    test('a valid invite emits sending, then the new team', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const TeamInviteSubmitted(_invite));

      expect(subject.states, const <TeamState>[
        TeamState(
          loadStatus: RequestStatus.success,
          members: testTeam,
          inviteStatus: RequestStatus.loading,
        ),
        TeamState(
          loadStatus: RequestStatus.success,
          members: _teamAfterInvite,
          inviteStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.repository.inviteParams.single.phone, '+77005551234');
    });

    test('a duplicate phone is shown on the phone field only', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.inviteResult =
          const Left<Failure, List<TeamMemberEntity>>(
            ValidationFailure(
              fieldErrors: <String, String>{
                ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
              },
            ),
          );

      await subject.add(const TeamInviteSubmitted(_invite));

      expect(subject.bloc.state.inviteStatus, RequestStatus.failure);
      expect(subject.bloc.state.inviteFieldErrors, const <String, String>{
        ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
      });
      expect(subject.bloc.state.inviteFailure, isNull);
      expect(subject.bloc.state.members, testTeam);
    });

    test(
      'a server error on a hidden field is also an invite failure',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        const Failure failure = ValidationFailure(
          fieldErrors: <String, String>{'role': 'invalid'},
        );
        subject.repository.inviteResult =
            const Left<Failure, List<TeamMemberEntity>>(failure);

        await subject.add(const TeamInviteSubmitted(_invite));

        expect(subject.bloc.state.inviteFailure, failure);
      },
    );

    test('the team limit is reported as the invite failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      const Failure failure = ValidationFailure(
        code: ProfileErrorCodes.teamLimitReached,
      );
      subject.repository.inviteResult =
          const Left<Failure, List<TeamMemberEntity>>(failure);

      await subject.add(const TeamInviteSubmitted(_invite));

      expect(subject.bloc.state.inviteStatus, RequestStatus.failure);
      expect(subject.bloc.state.inviteFailure, failure);
      expect(subject.bloc.state.inviteFieldErrors, isEmpty);
    });

    test('use case field errors are kept without sending', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(
        const TeamInviteSubmitted(
          InviteTeamMemberParamsEntity(
            firstName: '',
            lastName: 'Ахметова',
            phone: '123',
            role: ProfileRole.manager,
          ),
        ),
      );

      expect(subject.bloc.state.inviteFieldErrors, const <String, String>{
        ProfileFields.firstName: AuthErrorCodes.required,
        ProfileFields.phone: AuthErrorCodes.invalidPhone,
      });
      expect(subject.repository.inviteParams, isEmpty);
    });

    test('editing a field clears its error and the failure status', () async {
      final _Subject subject = _Subject();
      await subject.load();
      await subject.add(
        const TeamInviteSubmitted(
          InviteTeamMemberParamsEntity(
            firstName: '',
            lastName: '',
            phone: '700 555 12 34',
            role: ProfileRole.manager,
          ),
        ),
      );

      await subject.add(const TeamInviteFieldEdited(ProfileFields.lastName));

      expect(subject.bloc.state.inviteFieldErrors, const <String, String>{
        ProfileFields.firstName: AuthErrorCodes.required,
      });
      expect(subject.bloc.state.inviteStatus, RequestStatus.initial);
    });

    test('editing a field clears a general invite failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.inviteResult =
          const Left<Failure, List<TeamMemberEntity>>(_failure);
      await subject.add(const TeamInviteSubmitted(_invite));

      await subject.add(const TeamInviteFieldEdited(ProfileFields.phone));

      expect(subject.bloc.state.inviteFailure, isNull);
      expect(subject.bloc.state.inviteStatus, RequestStatus.initial);
    });

    test('editing without any error emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const TeamInviteFieldEdited(ProfileFields.phone));

      expect(subject.states, isEmpty);
    });

    test('a second invite while sending is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdInvite = true;

      await subject.add(const TeamInviteSubmitted(_invite));
      await subject.add(const TeamInviteSubmitted(_invite));
      subject.repository.heldInvite.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(_teamAfterInvite),
      );
      await pumpEventQueue();

      expect(subject.repository.inviteParams, hasLength(1));
      expect(subject.bloc.state.members, _teamAfterInvite);
    });

    test('starting a new invite clears the previous success', () async {
      final _Subject subject = _Subject();
      await subject.load();
      await subject.add(const TeamInviteSubmitted(_invite));
      expect(subject.bloc.state.inviteStatus, RequestStatus.success);

      await subject.add(const TeamInviteStarted());

      expect(subject.bloc.state.inviteStatus, RequestStatus.initial);
      expect(subject.bloc.state.members, _teamAfterInvite);
    });

    test('starting a new invite clears the previous failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.inviteResult =
          const Left<Failure, List<TeamMemberEntity>>(
            ValidationFailure(
              code: ProfileErrorCodes.teamLimitReached,
              fieldErrors: <String, String>{
                ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
              },
            ),
          );
      await subject.add(const TeamInviteSubmitted(_invite));
      expect(subject.bloc.state.inviteStatus, RequestStatus.failure);

      await subject.add(const TeamInviteStarted());

      expect(subject.bloc.state.inviteStatus, RequestStatus.initial);
      expect(subject.bloc.state.inviteFailure, isNull);
      expect(subject.bloc.state.inviteFieldErrors, isEmpty);
    });

    test('starting a new invite keeps an invite that is sending', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdInvite = true;
      await subject.add(const TeamInviteSubmitted(_invite));

      await subject.add(const TeamInviteStarted());

      expect(subject.bloc.state.inviteStatus, RequestStatus.loading);
      subject.repository.heldInvite.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(_teamAfterInvite),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.inviteStatus, RequestStatus.success);
    });

    test('an invite completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdInvite = true;
      await subject.add(const TeamInviteSubmitted(_invite));
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldInvite.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(_teamAfterInvite),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('TeamBloc remove', () {
    test('a removal marks the member, then publishes the new team', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const TeamMemberRemoveRequested('member-aliya'));

      expect(subject.states, const <TeamState>[
        TeamState(
          loadStatus: RequestStatus.success,
          members: testTeam,
          removeStatus: RequestStatus.loading,
          removingMemberId: 'member-aliya',
        ),
        TeamState(
          loadStatus: RequestStatus.success,
          members: _teamAfterRemove,
          removeStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.repository.removedMemberIds, <String>['member-aliya']);
    });

    test('a failed removal keeps the team and reports the failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      const Failure failure = ValidationFailure(
        code: ProfileErrorCodes.cannotRemoveOwner,
      );
      subject.repository.removeResult =
          const Left<Failure, List<TeamMemberEntity>>(failure);

      await subject.add(const TeamMemberRemoveRequested('member-owner'));

      expect(
        subject.bloc.state,
        const TeamState(
          loadStatus: RequestStatus.success,
          members: testTeam,
          removeStatus: RequestStatus.failure,
          removeFailure: failure,
        ),
      );
    });

    test('a new removal clears the earlier failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.removeResult =
          const Left<Failure, List<TeamMemberEntity>>(_failure);
      await subject.add(const TeamMemberRemoveRequested('member-aliya'));
      subject.repository.removeResult =
          const Right<Failure, List<TeamMemberEntity>>(_teamAfterRemove);
      subject.states.clear();

      await subject.add(const TeamMemberRemoveRequested('member-aliya'));

      expect(subject.states.first.removeFailure, isNull);
      expect(subject.bloc.state.removeStatus, RequestStatus.success);
    });

    test('a second removal while removing is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdRemove = true;

      await subject.add(const TeamMemberRemoveRequested('member-aliya'));
      await subject.add(const TeamMemberRemoveRequested('member-aigerim'));
      subject.repository.heldRemove.single.complete(
        const Right<Failure, List<TeamMemberEntity>>(_teamAfterRemove),
      );
      await pumpEventQueue();

      expect(subject.repository.removedMemberIds, <String>['member-aliya']);
    });
  });
}
