import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_property_settings_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_settings_bloc/property_settings_bloc.dart';

import '../../../../../helpers/fake_property_management_repository.dart';

const SavePropertySettingsParamsEntity _pause =
    SavePropertySettingsParamsEntity(propertyId: 'p1', acceptsBookings: false);

final class _Subject {
  _Subject() {
    bloc = PropertySettingsBloc(
      getSettings: GetPropertySettingsUsecase(repository),
      saveSettings: SavePropertySettingsUsecase(repository),
    );
    final StreamSubscription<PropertySettingsState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakePropertyManagementRepository repository =
      FakePropertyManagementRepository();
  late final PropertySettingsBloc bloc;
  final List<PropertySettingsState> states = <PropertySettingsState>[];

  Future<void> add(PropertySettingsEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('PropertySettingsBloc', () {
    test('starts with nothing loaded or saved', () {
      expect(_Subject().bloc.state, const PropertySettingsState());
    });

    test('a load emits loading, then the settings', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertySettingsRequested('p1'));

      expect(subject.repository.settingsIds, <String>['p1']);
      expect(subject.states, <PropertySettingsState>[
        const PropertySettingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.loading,
        ),
        PropertySettingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.success,
          settings: testPropertySettings(),
        ),
      ]);
    });

    test('a failed load emits the failure; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.settingsResult =
          const Left<Failure, PropertySettingsEntity>(ConnectionFailure());

      await subject.add(const PropertySettingsRequested('p1'));
      expect(
        subject.states.last,
        const PropertySettingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.failure,
          loadFailure: ConnectionFailure(),
        ),
      );

      subject.repository.settingsResult =
          Right<Failure, PropertySettingsEntity>(testPropertySettings());
      subject.states.clear();
      await subject.add(const PropertySettingsRequested('p1'));

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('a newer load wins when the older one finishes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSettings = true;
      await subject.add(const PropertySettingsRequested('p1'));
      await subject.add(const PropertySettingsRequested('p1'));

      subject.repository.heldSettings[1].complete(
        Right<Failure, PropertySettingsEntity>(
          testPropertySettings(acceptsBookings: false),
        ),
      );
      await pumpEventQueue();
      subject.repository.heldSettings[0].complete(
        Right<Failure, PropertySettingsEntity>(testPropertySettings()),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.settings!.acceptsBookings, isFalse);
    });

    test('a save forwards the params and replaces the settings', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertySettingsRequested('p1'));
      subject.states.clear();

      await subject.add(const PropertySettingsSubmitted(_pause));

      expect(subject.repository.saveSettingsCalls.single, (
        propertyId: 'p1',
        acceptsBookings: false,
      ));
      expect(subject.states, <PropertySettingsState>[
        PropertySettingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.success,
          settings: testPropertySettings(),
          saveStatus: RequestStatus.loading,
        ),
        PropertySettingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.success,
          settings: testPropertySettings(acceptsBookings: false),
          saveStatus: RequestStatus.success,
        ),
      ]);
    });

    test('a failed save keeps the settings and reports the failure', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertySettingsRequested('p1'));
      subject.repository.saveSettingsResult =
          const Left<Failure, PropertySettingsEntity>(TimeoutFailure());

      await subject.add(const PropertySettingsSubmitted(_pause));

      expect(subject.bloc.state.saveStatus, RequestStatus.failure);
      expect(subject.bloc.state.saveFailure, const TimeoutFailure());
      expect(subject.bloc.state.settings, testPropertySettings());
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('the next save clears the previous save failure', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertySettingsRequested('p1'));
      subject.repository.saveSettingsResult =
          const Left<Failure, PropertySettingsEntity>(TimeoutFailure());
      await subject.add(const PropertySettingsSubmitted(_pause));
      subject.repository.saveSettingsResult = null;
      subject.states.clear();

      await subject.add(const PropertySettingsSubmitted(_pause));

      expect(subject.states.first.saveStatus, RequestStatus.loading);
      expect(subject.states.first.saveFailure, isNull);
      expect(subject.bloc.state.saveStatus, RequestStatus.success);
      expect(subject.bloc.state.saveFailure, isNull);
    });

    test('a second save while saving is dropped', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertySettingsRequested('p1'));
      subject.repository.holdSaveSettings = true;

      await subject.add(const PropertySettingsSubmitted(_pause));
      await subject.add(
        const PropertySettingsSubmitted(
          SavePropertySettingsParamsEntity(
            propertyId: 'p1',
            acceptsBookings: true,
          ),
        ),
      );

      expect(subject.repository.saveSettingsCalls, hasLength(1));
      subject.repository.heldSaveSettings.single.complete(
        Right<Failure, PropertySettingsEntity>(
          testPropertySettings(acceptsBookings: false),
        ),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.saveStatus, RequestStatus.success);
      expect(subject.bloc.state.settings!.acceptsBookings, isFalse);
    });

    test(
      'a save finishing after close emits nothing and does not throw',
      () async {
        final _Subject subject = _Subject();
        await subject.add(const PropertySettingsRequested('p1'));
        subject.repository.holdSaveSettings = true;
        await subject.add(const PropertySettingsSubmitted(_pause));
        final int count = subject.states.length;

        await subject.bloc.close();
        subject.repository.heldSaveSettings.single.complete(
          Right<Failure, PropertySettingsEntity>(testPropertySettings()),
        );
        await pumpEventQueue();

        expect(subject.states, hasLength(count));
        expect(subject.bloc.state.saveStatus, RequestStatus.loading);
      },
    );
  });
}
