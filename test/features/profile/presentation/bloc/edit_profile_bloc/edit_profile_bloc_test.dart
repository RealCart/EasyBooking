import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/edit_profile_bloc/edit_profile_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

const UpdateProfileParamsEntity _params = UpdateProfileParamsEntity(
  firstName: ' Алихан ',
  lastName: 'Сейткали',
  email: 'a.seitkali@mail.kz',
  teamName: 'Алихан Апартаменты',
  city: KazakhstanCities.astana,
);

const ProfileDetailsEntity _savedDetails = ProfileDetailsEntity(
  firstName: 'Алихан',
  lastName: 'Сейткали',
  phone: '+77012345678',
  email: 'a.seitkali@mail.kz',
  teamName: 'Алихан Апартаменты',
  city: KazakhstanCities.astana,
);

/// An [EditProfileBloc] over a [FakeProfileRepository] that records its
/// states.
final class _Subject {
  _Subject() {
    repository.updateProfileResult = const Right<Failure, ProfileDetailsEntity>(
      _savedDetails,
    );
    bloc = EditProfileBloc(
      getProfileDetails: GetProfileDetailsUsecase(repository),
      updateProfile: UpdateProfileUsecase(repository),
    );
    final StreamSubscription<EditProfileState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final EditProfileBloc bloc;
  final List<EditProfileState> states = <EditProfileState>[];

  Future<void> add(EditProfileEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads the details, then forgets the recorded states.
  Future<void> load() async {
    await add(const EditProfileStarted());
    states.clear();
  }
}

void main() {
  group('EditProfileBloc load', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const EditProfileState());
    });

    test('a load emits loading, then the details', () async {
      final _Subject subject = _Subject();

      await subject.add(const EditProfileStarted());

      expect(subject.states, const <EditProfileState>[
        EditProfileState(loadStatus: RequestStatus.loading),
        EditProfileState(
          loadStatus: RequestStatus.success,
          details: testProfileDetails,
        ),
      ]);
    });

    test('a failed load emits the failure without details', () async {
      final _Subject subject = _Subject();
      subject.repository.detailsResult =
          const Left<Failure, ProfileDetailsEntity>(_failure);

      await subject.add(const EditProfileStarted());

      expect(subject.states, const <EditProfileState>[
        EditProfileState(loadStatus: RequestStatus.loading),
        EditProfileState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      ]);
    });

    test('a retry clears the earlier load failure', () async {
      final _Subject subject = _Subject();
      subject.repository.detailsResult =
          const Left<Failure, ProfileDetailsEntity>(_failure);
      await subject.add(const EditProfileStarted());
      subject.repository.detailsResult =
          const Right<Failure, ProfileDetailsEntity>(testProfileDetails);
      subject.states.clear();

      await subject.add(const EditProfileStarted());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.states.first.loadStatus, RequestStatus.loading);
      expect(subject.bloc.state.details, testProfileDetails);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdDetails = true;
      await subject.add(const EditProfileStarted());
      await subject.add(const EditProfileStarted());

      subject.repository.heldDetails[1].complete(
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      await pumpEventQueue();
      subject.repository.heldDetails[0].complete(
        const Right<Failure, ProfileDetailsEntity>(_savedDetails),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.details, testProfileDetails);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('a load that started before a save keeps the saved details', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdDetails = true;
      await subject.add(const EditProfileStarted());

      await subject.add(const EditProfileSubmitted(_params));
      subject.repository.heldDetails.single.complete(
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.details, _savedDetails);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.saveStatus, RequestStatus.success);
    });

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdDetails = true;
      await subject.add(const EditProfileStarted());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldDetails.single.complete(
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
      expect(subject.bloc.state.details, isNull);
    });
  });

  group('EditProfileBloc save', () {
    test('a valid form emits saving, then the saved details', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const EditProfileSubmitted(_params));

      expect(subject.states, const <EditProfileState>[
        EditProfileState(
          loadStatus: RequestStatus.success,
          details: testProfileDetails,
          saveStatus: RequestStatus.loading,
        ),
        EditProfileState(
          loadStatus: RequestStatus.success,
          details: _savedDetails,
          saveStatus: RequestStatus.success,
        ),
      ]);
      expect(
        subject.repository.updateProfileParams.single.firstName,
        'Алихан',
      );
    });

    test(
      'use case field errors are shown per field, not as a failure',
      () async {
        final _Subject subject = _Subject();
        await subject.load();

        await subject.add(
          const EditProfileSubmitted(
            UpdateProfileParamsEntity(
              firstName: ' ',
              lastName: 'Сейткали',
              email: 'bad',
              teamName: 'Команда',
              city: KazakhstanCities.astana,
            ),
          ),
        );

        final EditProfileState state = subject.bloc.state;
        expect(state.saveStatus, RequestStatus.failure);
        expect(state.fieldErrors, const <String, String>{
          ProfileFields.firstName: AuthErrorCodes.required,
          ProfileFields.email: AuthErrorCodes.invalidEmail,
        });
        expect(state.saveFailure, isNull);
        expect(subject.repository.updateProfileParams, isEmpty);
        expect(
          () => state.fieldErrors['x'] = 'y',
          throwsUnsupportedError,
        );
      },
    );

    test('a server error on a hidden field is also a save failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      const Failure failure = ValidationFailure(
        fieldErrors: <String, String>{ProfileFields.phone: 'taken'},
      );
      subject.repository.updateProfileResult =
          const Left<Failure, ProfileDetailsEntity>(failure);

      await subject.add(const EditProfileSubmitted(_params));

      expect(subject.bloc.state.fieldErrors, const <String, String>{
        ProfileFields.phone: 'taken',
      });
      expect(subject.bloc.state.saveFailure, failure);
    });

    test('another failure is reported as the save failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.updateProfileResult =
          const Left<Failure, ProfileDetailsEntity>(_failure);

      await subject.add(const EditProfileSubmitted(_params));

      expect(subject.bloc.state.saveStatus, RequestStatus.failure);
      expect(subject.bloc.state.saveFailure, _failure);
      expect(subject.bloc.state.details, testProfileDetails);
    });

    test('a second submit while saving is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdUpdateProfile = true;

      await subject.add(const EditProfileSubmitted(_params));
      await subject.add(const EditProfileSubmitted(_params));
      subject.repository.heldUpdateProfile.single.complete(
        const Right<Failure, ProfileDetailsEntity>(_savedDetails),
      );
      await pumpEventQueue();

      expect(subject.repository.updateProfileParams, hasLength(1));
      expect(subject.bloc.state.saveStatus, RequestStatus.success);
    });

    test('a resubmit clears the earlier errors while saving', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.updateProfileResult =
          const Left<Failure, ProfileDetailsEntity>(
            ValidationFailure(
              fieldErrors: <String, String>{ProfileFields.phone: 'taken'},
            ),
          );
      await subject.add(const EditProfileSubmitted(_params));
      subject.repository.updateProfileResult =
          const Right<Failure, ProfileDetailsEntity>(_savedDetails);
      subject.states.clear();

      await subject.add(const EditProfileSubmitted(_params));

      expect(subject.states.first.saveStatus, RequestStatus.loading);
      expect(subject.states.first.fieldErrors, isEmpty);
      expect(subject.states.first.saveFailure, isNull);
    });

    test('a save completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdUpdateProfile = true;
      await subject.add(const EditProfileSubmitted(_params));
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldUpdateProfile.single.complete(
        const Right<Failure, ProfileDetailsEntity>(_savedDetails),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('EditProfileBloc field edits', () {
    test('editing a field clears only its server error', () async {
      final _Subject subject = _Subject();
      await subject.load();
      await subject.add(
        const EditProfileSubmitted(
          UpdateProfileParamsEntity(
            firstName: '',
            lastName: '',
            email: 'a@b.kz',
            teamName: 'Команда',
            city: KazakhstanCities.astana,
          ),
        ),
      );

      await subject.add(const EditProfileFieldEdited(ProfileFields.firstName));

      expect(subject.bloc.state.fieldErrors, const <String, String>{
        ProfileFields.lastName: AuthErrorCodes.required,
      });
      expect(subject.bloc.state.saveStatus, RequestStatus.initial);
    });

    test('editing a field clears a general save failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.updateProfileResult =
          const Left<Failure, ProfileDetailsEntity>(_failure);
      await subject.add(const EditProfileSubmitted(_params));

      await subject.add(const EditProfileFieldEdited(ProfileFields.email));

      expect(subject.bloc.state.saveFailure, isNull);
      expect(subject.bloc.state.saveStatus, RequestStatus.initial);
    });

    test('editing without any error emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const EditProfileFieldEdited(ProfileFields.email));

      expect(subject.states, isEmpty);
    });
  });
}
