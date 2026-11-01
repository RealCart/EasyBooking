import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_bookings_bloc/property_bookings_bloc.dart';

import '../../../../../helpers/fake_properties_repository.dart';
import '../../../../../helpers/fake_property_management_repository.dart';

final class _Subject {
  _Subject() {
    bloc = PropertyBookingsBloc(
      getBookings: GetPropertyBookingsUsecase(repository),
    );
    final StreamSubscription<PropertyBookingsState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakePropertyManagementRepository repository =
      FakePropertyManagementRepository();
  late final PropertyBookingsBloc bloc;
  final List<PropertyBookingsState> states = <PropertyBookingsState>[];

  Future<void> add(PropertyBookingsEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }
}

/// [testPropertyBookings] with only the first upcoming booking.
PropertyBookingsEntity _otherBookings() {
  final PropertyBookingsEntity bookings = testPropertyBookings();
  return PropertyBookingsEntity(
    property: bookings.property,
    upcoming: <PropertyBookingEntity>[bookings.upcoming.first],
    past: const <PropertyBookingEntity>[],
    receivedAt: bookings.receivedAt,
  );
}

void main() {
  group('PropertyBookingsBloc', () {
    test('starts empty on the upcoming period', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const PropertyBookingsState());
      expect(subject.bloc.state.period, PropertyBookingsPeriod.upcoming);
      expect(subject.bloc.state.visibleBookings, isEmpty);
    });

    test('a load emits loading, then the bookings', () async {
      final _Subject subject = _Subject();

      await subject.add(const PropertyBookingsRequested('p1'));

      expect(subject.repository.bookingsIds, <String>['p1']);
      expect(subject.states, <PropertyBookingsState>[
        const PropertyBookingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.loading,
        ),
        PropertyBookingsState(
          propertyId: 'p1',
          loadStatus: RequestStatus.success,
          bookings: testPropertyBookings(),
        ),
      ]);
      expect(
        subject.bloc.state.visibleBookings,
        testPropertyBookings().upcoming,
      );
    });

    test('a failed load emits loading, then the failure', () async {
      final _Subject subject = _Subject();
      subject.repository.bookingsResult =
          const Left<Failure, PropertyBookingsEntity>(
            ServerFailure(statusCode: 404),
          );

      await subject.add(const PropertyBookingsRequested('missing'));

      expect(subject.states, <PropertyBookingsState>[
        const PropertyBookingsState(
          propertyId: 'missing',
          loadStatus: RequestStatus.loading,
        ),
        const PropertyBookingsState(
          propertyId: 'missing',
          loadStatus: RequestStatus.failure,
          loadFailure: ServerFailure(statusCode: 404),
        ),
      ]);
    });

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      subject.repository.bookingsResult =
          const Left<Failure, PropertyBookingsEntity>(ConnectionFailure());
      await subject.add(const PropertyBookingsRequested('p1'));
      subject.repository.bookingsResult =
          Right<Failure, PropertyBookingsEntity>(testPropertyBookings());
      subject.states.clear();

      await subject.add(const PropertyBookingsRequested('p1'));

      expect(subject.states.first.loadStatus, RequestStatus.loading);
      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.loadFailure, isNull);
    });

    test('a failed refresh keeps the shown bookings', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertyBookingsRequested('p1'));
      subject.repository.bookingsResult =
          const Left<Failure, PropertyBookingsEntity>(TimeoutFailure());

      await subject.add(const PropertyBookingsRequested('p1'));

      expect(subject.bloc.state.loadStatus, RequestStatus.failure);
      expect(subject.bloc.state.loadFailure, const TimeoutFailure());
      expect(subject.bloc.state.bookings, testPropertyBookings());
    });

    test('a newer load wins when the older one finishes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdBookings = true;
      await subject.add(const PropertyBookingsRequested('p1'));
      await subject.add(const PropertyBookingsRequested('p1'));
      expect(subject.repository.heldBookings, hasLength(2));

      subject.repository.heldBookings[1].complete(
        Right<Failure, PropertyBookingsEntity>(_otherBookings()),
      );
      await pumpEventQueue();
      subject.repository.heldBookings[0].complete(
        const Left<Failure, PropertyBookingsEntity>(ConnectionFailure()),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.bookings, _otherBookings());
      expect(subject.bloc.state.loadFailure, isNull);
      expect(
        subject.states.where(
          (PropertyBookingsState state) => state.loadStatus.isFailure,
        ),
        isEmpty,
      );
    });

    test('a period switches the visible bookings and keeps the data', () async {
      final _Subject subject = _Subject();
      await subject.add(const PropertyBookingsRequested('p1'));

      await subject.add(
        const PropertyBookingsPeriodSelected(PropertyBookingsPeriod.past),
      );

      expect(subject.bloc.state.period, PropertyBookingsPeriod.past);
      expect(subject.bloc.state.visibleBookings, testPropertyBookings().past);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);

      await subject.add(
        const PropertyBookingsPeriodSelected(PropertyBookingsPeriod.upcoming),
      );
      expect(
        subject.bloc.state.visibleBookings,
        testPropertyBookings().upcoming,
      );
    });

    test('a period chosen before the load is kept after it', () async {
      final _Subject subject = _Subject();

      await subject.add(
        const PropertyBookingsPeriodSelected(PropertyBookingsPeriod.past),
      );
      expect(subject.bloc.state.visibleBookings, isEmpty);
      await subject.add(const PropertyBookingsRequested('p1'));

      expect(subject.bloc.state.period, PropertyBookingsPeriod.past);
      expect(subject.bloc.state.visibleBookings, testPropertyBookings().past);
    });

    test(
      'a load finishing after close emits nothing and does not throw',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdBookings = true;
        await subject.add(const PropertyBookingsRequested('p1'));
        final int count = subject.states.length;

        await subject.bloc.close();
        subject.repository.heldBookings.single.complete(
          Right<Failure, PropertyBookingsEntity>(testPropertyBookings()),
        );
        await pumpEventQueue();

        expect(subject.states, hasLength(count));
        expect(subject.bloc.state.loadStatus, RequestStatus.loading);
      },
    );

    test('the test bookings belong to the shared test property', () {
      expect(testPropertyBookings().property, testProperties().first);
    });
  });
}
