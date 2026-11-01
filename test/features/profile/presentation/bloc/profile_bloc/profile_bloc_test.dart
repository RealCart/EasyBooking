import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';
import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [ProfileBloc] over fake profile and auth repositories that records
/// its states.
final class _Subject {
  _Subject() {
    bloc = ProfileBloc(
      getProfile: GetProfileUsecase(profiles),
      signOut: SignOutUsecase(auth),
    );
    final StreamSubscription<ProfileState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository profiles = FakeProfileRepository();
  final FakeAuthRepository auth = FakeAuthRepository();
  late final ProfileBloc bloc;
  final List<ProfileState> states = <ProfileState>[];

  Future<void> add(ProfileEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('ProfileBloc', () {
    test('a load emits loading, then the profile', () async {
      final _Subject subject = _Subject();

      await subject.add(const ProfileRequested());

      expect(subject.states, const <ProfileState>[
        ProfileState(loadStatus: RequestStatus.loading),
        ProfileState(loadStatus: RequestStatus.success, profile: testProfile),
      ]);
    });

    test('a failed load emits the failure without a profile', () async {
      final _Subject subject = _Subject();
      subject.profiles.profileResult = const Left<Failure, ProfileEntity>(
        _failure,
      );

      await subject.add(const ProfileRequested());

      expect(
        subject.states.last,
        const ProfileState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      );
    });

    test('a failed refresh keeps the profile', () async {
      final _Subject subject = _Subject();
      await subject.add(const ProfileRequested());
      subject.profiles.profileResult = const Left<Failure, ProfileEntity>(
        _failure,
      );

      await subject.add(const ProfileRequested());

      expect(subject.bloc.state.profile, testProfile);
      expect(subject.bloc.state.loadFailure, _failure);
    });

    test('sign out ignores a second request while the first runs', () async {
      final _Subject subject = _Subject();
      subject.auth.holdSignOut = true;

      await subject.add(const ProfileSignOutRequested());
      await subject.add(const ProfileSignOutRequested());
      subject.auth.heldSignOuts.single.complete(voidSuccess);
      await pumpEventQueue();

      expect(subject.auth.signOutCount, 1);
      expect(subject.states, const <ProfileState>[
        ProfileState(signOutStatus: RequestStatus.loading),
        ProfileState(signOutStatus: RequestStatus.success),
      ]);
    });

    test('a failed sign out reports the failure', () async {
      final _Subject subject = _Subject();
      subject.auth.signOutResult = const Left<Failure, void>(
        StorageFailure(),
      );

      await subject.add(const ProfileSignOutRequested());

      expect(subject.bloc.state.signOutStatus, RequestStatus.failure);
      expect(subject.bloc.state.signOutFailure, const StorageFailure());
    });

    test('a retried sign out clears the earlier failure', () async {
      final _Subject subject = _Subject();
      subject.auth.signOutResult = const Left<Failure, void>(
        StorageFailure(),
      );
      await subject.add(const ProfileSignOutRequested());
      subject.auth.signOutResult = voidSuccess;
      subject.states.clear();

      await subject.add(const ProfileSignOutRequested());

      expect(subject.states.first.signOutFailure, isNull);
      expect(subject.bloc.state.signOutStatus, RequestStatus.success);
    });
  });
}
