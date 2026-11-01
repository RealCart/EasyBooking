import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_detail_bloc/property_detail_bloc.dart';

import '../../../../../helpers/fake_properties_repository.dart';

final class _Subject {
  _Subject() {
    bloc = PropertyDetailBloc(
      getProperty: GetPropertyUsecase(repository),
      setFavorite: SetPropertyFavoriteUsecase(repository),
    );
    final StreamSubscription<PropertyDetailState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakePropertiesRepository repository = FakePropertiesRepository();
  late final PropertyDetailBloc bloc;
  final List<PropertyDetailState> states = <PropertyDetailState>[];

  Future<void> add(PropertyDetailEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

void main() {
  group('PropertyDetailBloc', () {
    test('a load emits loading, then the property', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertyDetailRequested('p2'));

      expect(subject.states, <PropertyDetailState>[
        const PropertyDetailState(
          propertyId: 'p2',
          loadStatus: RequestStatus.loading,
        ),
        PropertyDetailState(
          propertyId: 'p2',
          loadStatus: RequestStatus.success,
          property: testProperties()[1],
        ),
      ]);
    });

    test('an unknown property fails with 404', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertyDetailRequested('missing'));

      expect(subject.bloc.state.loadStatus, RequestStatus.failure);
      expect(
        subject.bloc.state.loadFailure,
        const ServerFailure(statusCode: 404),
      );
      expect(subject.bloc.state.property, isNull);
    });

    test('the heart flips after the write succeeds', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertyDetailRequested('p1'));

      await subject.add(const PropertyDetailFavoriteToggled());

      expect(subject.repository.favoriteCalls.single, (
        propertyId: 'p1',
        isFavorite: false,
      ));
      expect(subject.bloc.state.property!.isFavorite, isFalse);
    });

    test('a failed write keeps the heart and reports it', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertyDetailRequested('p1'));
      subject.repository.setFavoriteResult = const Left<Failure, void>(
        ConnectionFailure(),
      );

      await subject.add(const PropertyDetailFavoriteToggled());

      expect(subject.bloc.state.property!.isFavorite, isTrue);
      expect(subject.bloc.state.favoriteFailure, const ConnectionFailure());
    });

    test('the heart does nothing before the property loads', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertyDetailFavoriteToggled());

      expect(subject.repository.favoriteCalls, isEmpty);
    });
  });
}
