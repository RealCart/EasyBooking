import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/notification_settings_bloc/notification_settings_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

const UpdateNotificationSettingsParamsEntity _params =
    UpdateNotificationSettingsParamsEntity(
      enabledTopics: <NotificationTopic>{NotificationTopic.priceChange},
      channels: <NotificationDeliveryChannel>{
        NotificationDeliveryChannel.email,
      },
    );

const NotificationSettingsEntity _saved = NotificationSettingsEntity(
  enabledTopics: <NotificationTopic>{NotificationTopic.priceChange},
  channels: <NotificationDeliveryChannel>{NotificationDeliveryChannel.email},
);

/// A [NotificationSettingsBloc] over a [FakeProfileRepository] that records
/// its states.
final class _Subject {
  _Subject() {
    repository.updateNotificationSettingsResult =
        const Right<Failure, NotificationSettingsEntity>(_saved);
    bloc = NotificationSettingsBloc(
      getNotificationSettings: GetNotificationSettingsUsecase(repository),
      updateNotificationSettings: UpdateNotificationSettingsUsecase(
        repository,
      ),
    );
    final StreamSubscription<NotificationSettingsState> subscription = bloc
        .stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final NotificationSettingsBloc bloc;
  final List<NotificationSettingsState> states = <NotificationSettingsState>[];

  Future<void> add(NotificationSettingsEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> load() async {
    await add(const NotificationSettingsRequested());
    states.clear();
  }
}

void main() {
  group('NotificationSettingsBloc load', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const NotificationSettingsState());
    });

    test('a load emits loading, then the settings', () async {
      final _Subject subject = _Subject();

      await subject.add(const NotificationSettingsRequested());

      expect(subject.states, const <NotificationSettingsState>[
        NotificationSettingsState(loadStatus: RequestStatus.loading),
        NotificationSettingsState(
          loadStatus: RequestStatus.success,
          settings: testNotificationSettings,
        ),
      ]);
    });

    test('a failed load emits the failure; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.notificationSettingsResult =
          const Left<Failure, NotificationSettingsEntity>(_failure);

      await subject.add(const NotificationSettingsRequested());

      expect(
        subject.bloc.state,
        const NotificationSettingsState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      );

      subject.repository.notificationSettingsResult =
          const Right<Failure, NotificationSettingsEntity>(
            testNotificationSettings,
          );
      subject.states.clear();
      await subject.add(const NotificationSettingsRequested());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.settings, testNotificationSettings);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdNotificationSettings = true;
      await subject.add(const NotificationSettingsRequested());
      await subject.add(const NotificationSettingsRequested());

      subject.repository.heldNotificationSettings[1].complete(
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      await pumpEventQueue();
      subject.repository.heldNotificationSettings[0].complete(
        const Right<Failure, NotificationSettingsEntity>(_saved),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.settings, testNotificationSettings);
    });

    test(
      'a load that started before a save keeps the saved settings',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.holdNotificationSettings = true;
        await subject.add(const NotificationSettingsRequested());

        await subject.add(const NotificationSettingsSubmitted(_params));
        subject.repository.heldNotificationSettings.single.complete(
          const Right<Failure, NotificationSettingsEntity>(
            testNotificationSettings,
          ),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.settings, _saved);
        expect(subject.bloc.state.loadStatus, RequestStatus.success);
      },
    );

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdNotificationSettings = true;
      await subject.add(const NotificationSettingsRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldNotificationSettings.single.complete(
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('NotificationSettingsBloc save', () {
    test('a save emits saving, then the saved settings', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const NotificationSettingsSubmitted(_params));

      expect(subject.states, const <NotificationSettingsState>[
        NotificationSettingsState(
          loadStatus: RequestStatus.success,
          settings: testNotificationSettings,
          saveStatus: RequestStatus.loading,
        ),
        NotificationSettingsState(
          loadStatus: RequestStatus.success,
          settings: _saved,
          saveStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.repository.updateNotificationSettingsParams, <Object>[
        _params,
      ]);
    });

    test(
      'no channel fails with noDeliveryChannel and keeps the settings',
      () async {
        final _Subject subject = _Subject();
        await subject.load();

        await subject.add(
          const NotificationSettingsSubmitted(
            UpdateNotificationSettingsParamsEntity(
              enabledTopics: <NotificationTopic>{},
              channels: <NotificationDeliveryChannel>{},
            ),
          ),
        );

        expect(subject.bloc.state.saveStatus, RequestStatus.failure);
        expect(
          subject.bloc.state.saveFailure,
          const ValidationFailure(code: ProfileErrorCodes.noDeliveryChannel),
        );
        expect(subject.bloc.state.settings, testNotificationSettings);
        expect(subject.repository.updateNotificationSettingsParams, isEmpty);
      },
    );

    test('a new save clears the earlier failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.updateNotificationSettingsResult =
          const Left<Failure, NotificationSettingsEntity>(_failure);
      await subject.add(const NotificationSettingsSubmitted(_params));
      subject.repository.updateNotificationSettingsResult =
          const Right<Failure, NotificationSettingsEntity>(_saved);
      subject.states.clear();

      await subject.add(const NotificationSettingsSubmitted(_params));

      expect(subject.states.first.saveFailure, isNull);
      expect(subject.bloc.state.saveStatus, RequestStatus.success);
    });

    test('a second save while saving is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdUpdateNotificationSettings = true;

      await subject.add(const NotificationSettingsSubmitted(_params));
      await subject.add(const NotificationSettingsSubmitted(_params));
      subject.repository.heldUpdateNotificationSettings.single.complete(
        const Right<Failure, NotificationSettingsEntity>(_saved),
      );
      await pumpEventQueue();

      expect(subject.repository.updateNotificationSettingsParams, hasLength(1));
    });

    test('a save completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdUpdateNotificationSettings = true;
      await subject.add(const NotificationSettingsSubmitted(_params));
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldUpdateNotificationSettings.single.complete(
        const Right<Failure, NotificationSettingsEntity>(_saved),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });
}
