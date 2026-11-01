import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/publish_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_channels_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/add_property_bloc/add_property_bloc.dart';

import '../../../../../helpers/fake_property_management_repository.dart';

const SaveAddPropertyDetailsParamsEntity _details =
    SaveAddPropertyDetailsParamsEntity(
      title: 'Al-Farabi Residence · 19',
      address: 'Аль-Фараби, 21',
      type: PropertyType.house,
      rooms: 3,
    );

const AddPropertyDetailsSubmitted _detailsSubmitted =
    AddPropertyDetailsSubmitted(_details);

/// Fails validation on the title and the address.
const AddPropertyDetailsSubmitted _blankSubmitted = AddPropertyDetailsSubmitted(
  SaveAddPropertyDetailsParamsEntity(
    title: ' ',
    address: '',
    type: PropertyType.apartment,
    rooms: 2,
  ),
);

const AddPropertyChannelsSubmitted _channelsSubmitted =
    AddPropertyChannelsSubmitted(
      SaveAddPropertyChannelsParamsEntity(
        channels: <BookingChannel>[BookingChannel.airbnb],
      ),
    );

const AddPropertyTermsSubmitted _termsSubmitted = AddPropertyTermsSubmitted(
  PublishPropertyParamsEntity(terms: testTerms),
);

final class _Subject {
  _Subject() {
    bloc = AddPropertyBloc(
      getDraft: GetAddPropertyDraftUsecase(repository),
      saveDetails: SaveAddPropertyDetailsUsecase(repository),
      saveChannels: SaveAddPropertyChannelsUsecase(repository),
      publish: PublishPropertyUsecase(repository),
    );
    final StreamSubscription<AddPropertyState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakePropertyManagementRepository repository =
      FakePropertyManagementRepository();
  late final AddPropertyBloc bloc;
  final List<AddPropertyState> states = <AddPropertyState>[];

  Future<void> add(AddPropertyEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('AddPropertyBloc draft', () {
    test('starts with nothing loaded or submitted', () {
      expect(_Subject().bloc.state, const AddPropertyState());
    });

    test('Started emits loading, then the draft', () async {
      final _Subject subject = _Subject();
      subject.repository.draftResult =
          const Right<Failure, AddPropertyDraftEntity>(testFilledDraft);

      await subject.add(const AddPropertyStarted());

      expect(subject.states, const <AddPropertyState>[
        AddPropertyState(draftStatus: RequestStatus.loading),
        AddPropertyState(
          draftStatus: RequestStatus.success,
          draft: testFilledDraft,
        ),
      ]);
    });

    test('a failed draft load is reported; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.draftResult =
          const Left<Failure, AddPropertyDraftEntity>(StorageFailure());

      await subject.add(const AddPropertyStarted());
      expect(
        subject.bloc.state,
        const AddPropertyState(
          draftStatus: RequestStatus.failure,
          draftFailure: StorageFailure(),
        ),
      );

      subject.repository.draftResult =
          const Right<Failure, AddPropertyDraftEntity>(testEmptyDraft);
      subject.states.clear();
      await subject.add(const AddPropertyStarted());

      expect(subject.states, const <AddPropertyState>[
        AddPropertyState(draftStatus: RequestStatus.loading),
        AddPropertyState(
          draftStatus: RequestStatus.success,
          draft: testEmptyDraft,
        ),
      ]);
    });

    test('a newer draft load wins when the older one finishes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdDraft = true;
      await subject.add(const AddPropertyStarted());
      await subject.add(const AddPropertyStarted());

      subject.repository.heldDraft[1].complete(
        const Right<Failure, AddPropertyDraftEntity>(testFilledDraft),
      );
      await pumpEventQueue();
      subject.repository.heldDraft[0].complete(
        const Left<Failure, AddPropertyDraftEntity>(StorageFailure()),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.draftStatus, RequestStatus.success);
      expect(subject.bloc.state.draft, testFilledDraft);
      expect(subject.bloc.state.draftFailure, isNull);
    });
  });

  group('AddPropertyBloc submit', () {
    test('details are saved: loading, then success', () async {
      final _Subject subject = _Subject();

      await subject.add(_detailsSubmitted);

      expect(subject.repository.savedDetails.single, _details);
      expect(subject.states, const <AddPropertyState>[
        AddPropertyState(submitStatus: RequestStatus.loading),
        AddPropertyState(submitStatus: RequestStatus.success),
      ]);
    });

    test('channels are saved: loading, then success', () async {
      final _Subject subject = _Subject();

      await subject.add(_channelsSubmitted);

      expect(subject.repository.savedChannels.single, const <BookingChannel>[
        BookingChannel.airbnb,
      ]);
      expect(subject.bloc.state.submitStatus, RequestStatus.success);
    });

    test('field errors of a ValidationFailure go to fieldErrors', () async {
      final _Subject subject = _Subject();

      await subject.add(_blankSubmitted);

      expect(subject.repository.savedDetails, isEmpty);
      expect(
        subject.bloc.state,
        const AddPropertyState(
          submitStatus: RequestStatus.failure,
          fieldErrors: <String, String>{
            AddPropertyFields.title: PropertyErrorCodes.required,
            AddPropertyFields.address: PropertyErrorCodes.required,
          },
        ),
      );
      expect(
        () => subject.bloc.state.fieldErrors['x'] = 'y',
        throwsUnsupportedError,
      );
    });

    test('a failure without field errors goes to submitFailure', () async {
      final _Subject subject = _Subject();
      subject.repository.saveDetailsResult = const Left<Failure, void>(
        StorageFailure(message: 'disk'),
      );

      await subject.add(_detailsSubmitted);

      expect(
        subject.bloc.state,
        const AddPropertyState(
          submitStatus: RequestStatus.failure,
          submitFailure: StorageFailure(message: 'disk'),
        ),
      );
    });

    test('a new submit clears the previous field errors', () async {
      final _Subject subject = _Subject();
      await subject.add(_blankSubmitted);
      subject.states.clear();

      await subject.add(_detailsSubmitted);

      expect(subject.states.first.submitStatus, RequestStatus.loading);
      expect(subject.states.first.fieldErrors, isEmpty);
      expect(subject.bloc.state.submitStatus, RequestStatus.success);
    });

    test('a submit while another one is loading is ignored', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSaveDetails = true;

      await subject.add(_detailsSubmitted);
      await subject.add(_detailsSubmitted);
      await subject.add(_channelsSubmitted);
      await subject.add(_termsSubmitted);

      expect(subject.repository.savedDetails, hasLength(1));
      expect(subject.repository.savedChannels, isEmpty);
      expect(subject.repository.publishedTerms, isEmpty);

      subject.repository.heldSaveDetails.single.complete(
        const Right<Failure, void>(null),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.submitStatus, RequestStatus.success);
      expect(subject.bloc.state.publishedPropertyId, isNull);
    });

    test('a submit finishing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSaveDetails = true;
      await subject.add(_detailsSubmitted);
      final int count = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldSaveDetails.single.complete(
        const Right<Failure, void>(null),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(count));
      expect(subject.bloc.state.submitStatus, RequestStatus.loading);
    });
  });

  group('AddPropertyBloc publish', () {
    test('publishing stores the new id with success', () async {
      final _Subject subject = _Subject();

      await subject.add(_termsSubmitted);

      expect(subject.repository.publishedTerms.single, testTerms);
      expect(subject.states, const <AddPropertyState>[
        AddPropertyState(submitStatus: RequestStatus.loading),
        AddPropertyState(
          submitStatus: RequestStatus.success,
          publishedPropertyId: 'new-property-1',
        ),
      ]);
    });

    test('publishes only once', () async {
      final _Subject subject = _Subject();
      await subject.add(_termsSubmitted);
      subject.states.clear();

      await subject.add(_termsSubmitted);

      expect(subject.repository.publishedTerms, hasLength(1));
      expect(subject.states, isEmpty);
      expect(subject.bloc.state.publishedPropertyId, 'new-property-1');
    });

    test('a second tap while publishing is dropped', () async {
      final _Subject subject = _Subject();
      subject.repository.holdPublish = true;

      await subject.add(_termsSubmitted);
      await subject.add(_termsSubmitted);

      expect(subject.repository.publishedTerms, hasLength(1));
      subject.repository.heldPublish.single.complete(
        const Right<Failure, String>('new-property-7'),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.publishedPropertyId, 'new-property-7');
    });

    test('draftIncomplete goes to submitFailure', () async {
      final _Subject subject = _Subject();
      subject.repository.publishResult = const Left<Failure, String>(
        ValidationFailure(code: PropertyErrorCodes.draftIncomplete),
      );

      await subject.add(_termsSubmitted);

      expect(
        subject.bloc.state,
        const AddPropertyState(
          submitStatus: RequestStatus.failure,
          submitFailure: ValidationFailure(
            code: PropertyErrorCodes.draftIncomplete,
          ),
        ),
      );
    });

    test('invalid terms go to fieldErrors and nothing is published', () async {
      final _Subject subject = _Subject();

      await subject.add(
        const AddPropertyTermsSubmitted(
          PublishPropertyParamsEntity(
            terms: PropertyTermsEntity(
              pricePerNight: 0,
              deposit: 0,
              checkInTime: Duration(hours: 14),
              checkOutTime: Duration(hours: 12),
              minNights: 2,
              cleaningFee: 0,
            ),
          ),
        ),
      );

      expect(subject.repository.publishedTerms, isEmpty);
      expect(subject.bloc.state.fieldErrors, const <String, String>{
        AddPropertyFields.pricePerNight: PropertyErrorCodes.outOfRange,
      });
      expect(subject.bloc.state.publishedPropertyId, isNull);
    });
  });

  group('AddPropertyBloc FieldEdited', () {
    test('clears only the edited field and the failure status', () async {
      final _Subject subject = _Subject();
      await subject.add(_blankSubmitted);

      await subject.add(const AddPropertyFieldEdited(AddPropertyFields.title));

      expect(
        subject.bloc.state,
        const AddPropertyState(
          fieldErrors: <String, String>{
            AddPropertyFields.address: PropertyErrorCodes.required,
          },
        ),
      );
      expect(
        () => subject.bloc.state.fieldErrors['x'] = 'y',
        throwsUnsupportedError,
      );
    });

    test('clears a general submit failure', () async {
      final _Subject subject = _Subject();
      subject.repository.saveDetailsResult = const Left<Failure, void>(
        ConnectionFailure(),
      );
      await subject.add(_detailsSubmitted);

      await subject.add(const AddPropertyFieldEdited(AddPropertyFields.rooms));

      expect(subject.bloc.state, const AddPropertyState());
    });

    test('emits nothing when there is no error to clear', () async {
      final _Subject subject = _Subject();
      await subject.add(_detailsSubmitted);
      subject.states.clear();

      await subject.add(const AddPropertyFieldEdited(AddPropertyFields.title));

      expect(subject.states, isEmpty);
      expect(subject.bloc.state.submitStatus, RequestStatus.success);
    });
  });
}
