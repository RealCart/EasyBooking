import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_list_options.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/properties_bloc/properties_bloc.dart';

import '../../../../../helpers/fake_properties_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [PropertiesBloc] over a [FakePropertiesRepository].
final class _Subject {
  _Subject() {
    bloc = PropertiesBloc(
      getProperties: GetPropertiesUsecase(repository),
      setFavorite: SetPropertyFavoriteUsecase(repository),
    );
    final StreamSubscription<PropertiesState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakePropertiesRepository repository = FakePropertiesRepository();
  late final PropertiesBloc bloc;
  final List<PropertiesState> states = <PropertiesState>[];

  Future<void> add(PropertiesEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> loaded() async {
    await add(const PropertiesRequested());
    states.clear();
  }

  List<String> get visibleIds => <String>[
    for (final PropertyEntity property in bloc.state.visibleProperties)
      property.id,
  ];
}

void main() {
  group('PropertiesBloc', () {
    test('a load emits loading, then the properties', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertiesRequested());

      expect(subject.states, <PropertiesState>[
        const PropertiesState(loadStatus: RequestStatus.loading),
        PropertiesState(
          loadStatus: RequestStatus.success,
          properties: testProperties(),
        ),
      ]);
      expect(subject.bloc.state.countFor(PropertiesFilter.busy), 1);
      expect(subject.bloc.state.favorites.single.id, 'p1');
    });

    test('a failed load keeps nothing and reports the failure', () async {
      final _Subject subject = _Subject();
      subject.repository.propertiesResult =
          const Left<Failure, List<PropertyEntity>>(_failure);

      await subject.add(const PropertiesRequested());

      expect(subject.bloc.state.loadFailure, _failure);
      expect(subject.bloc.state.hasLoaded, isFalse);
    });

    test('a failed refresh keeps the list', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.propertiesResult =
          const Left<Failure, List<PropertyEntity>>(_failure);

      await subject.add(const PropertiesRequested());

      expect(subject.bloc.state.properties, testProperties());
      expect(subject.bloc.state.hasLoaded, isTrue);
    });

    test('filter, query, and sort combine', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const PropertiesSortSelected(PropertySort.priceLow));
      expect(subject.visibleIds, <String>['p2', 'p1']);

      await subject.add(const PropertiesFilterSelected(PropertiesFilter.free));
      expect(subject.visibleIds, <String>['p2']);

      await subject.add(const PropertiesQueryChanged('esentai'));
      expect(subject.visibleIds, isEmpty);

      await subject.add(const PropertiesFilterSelected(PropertiesFilter.all));
      expect(subject.visibleIds, <String>['p1']);
    });

    test('a heart flips after the write succeeds', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const PropertyFavoriteToggled('p2'));

      expect(subject.repository.favoriteCalls.single, (
        propertyId: 'p2',
        isFavorite: true,
      ));
      expect(subject.bloc.state.propertyById('p2')!.isFavorite, isTrue);
    });

    test('two quick taps write true then false', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      subject.bloc
        ..add(const PropertyFavoriteToggled('p2'))
        ..add(const PropertyFavoriteToggled('p2'));
      await pumpEventQueue();

      expect(
        subject.repository.favoriteCalls.map(
          (({String propertyId, bool isFavorite}) call) => call.isFavorite,
        ),
        <bool>[true, false],
      );
      expect(subject.bloc.state.propertyById('p2')!.isFavorite, isFalse);
    });

    test('a failed write keeps the heart and reports it', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.setFavoriteResult = const Left<Failure, void>(
        _failure,
      );

      await subject.add(const PropertyFavoriteToggled('p1'));

      expect(subject.bloc.state.propertyById('p1')!.isFavorite, isTrue);
      expect(subject.bloc.state.favoriteFailure, _failure);
    });

    test(
      'a load that started before a favourite write keeps the heart',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.holdProperties = true;
        await subject.add(const PropertiesRequested());

        await subject.add(const PropertyFavoriteToggled('p2'));
        subject.repository.heldProperties.single.complete(
          Right<Failure, List<PropertyEntity>>(testProperties()),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.propertyById('p2')!.isFavorite, isTrue);
        expect(subject.bloc.state.loadStatus, RequestStatus.success);
      },
    );

    test('a load that started before a failed write applies', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.holdProperties = true;
      subject.repository.setFavoriteResult = const Left<Failure, void>(
        _failure,
      );
      await subject.add(const PropertiesRequested());

      await subject.add(const PropertyFavoriteToggled('p2'));
      subject.repository.heldProperties.single.complete(
        const Right<Failure, List<PropertyEntity>>(<PropertyEntity>[]),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.properties, isEmpty);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdProperties = true;

      await subject.add(const PropertiesRequested());
      await subject.add(const PropertiesRequested());
      subject.repository.heldProperties[1].complete(
        Right<Failure, List<PropertyEntity>>(testProperties()),
      );
      await pumpEventQueue();
      subject.repository.heldProperties[0].complete(
        const Right<Failure, List<PropertyEntity>>(<PropertyEntity>[]),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.properties, testProperties());
    });
  });
}
