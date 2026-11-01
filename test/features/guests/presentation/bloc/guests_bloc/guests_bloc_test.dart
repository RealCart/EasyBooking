import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guests_bloc/guests_bloc.dart';

import '../../../../../helpers/fake_guests_repository.dart';

const Failure _failure = ConnectionFailure();

/// A [GuestsBloc] over a [FakeGuestsRepository] that records its states.
final class _Subject {
  _Subject() {
    bloc = GuestsBloc(getDirectory: GetGuestDirectoryUsecase(repository));
    final StreamSubscription<GuestsState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
  }

  final FakeGuestsRepository repository = FakeGuestsRepository();
  late final GuestsBloc bloc;
  final List<GuestsState> states = <GuestsState>[];
}

/// Flushes microtasks inside the `testWidgets` fake-async zone.
Future<void> _flush(WidgetTester tester) => tester.pump();

/// Closes [bloc] inside the fake-async zone; `Bloc.close` does not complete
/// there, so it is not awaited.
Future<void> _close(WidgetTester tester, GuestsBloc bloc) async {
  unawaited(bloc.close());
  await tester.pump();
  expect(bloc.isClosed, isTrue);
}

/// Types [query] and waits out the debounce.
Future<void> _search(
  WidgetTester tester,
  _Subject subject,
  String query,
) async {
  subject.bloc.add(GuestsQueryChanged(query));
  await tester.pump(GuestsBloc.queryDebounce);
  await _flush(tester);
}

GuestDirectoryEntity _directoryFor(String query) {
  return testGuestDirectory(query: query);
}

void main() {
  group('GuestsBloc', () {
    test('starts empty and idle', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      expect(subject.bloc.state, const GuestsState());
      expect(subject.bloc.state.hasLoaded, isFalse);
      expect(subject.bloc.state.guests, isEmpty);
      expect(subject.bloc.state.contracts, isEmpty);
    });

    test(
      'a load emits loading, then the directory for the empty query',
      () async {
        final _Subject subject = _Subject();
        addTearDown(subject.bloc.close);

        subject.bloc.add(const GuestsRequested());
        await pumpEventQueue();

        expect(subject.repository.directoryQueries, <String>['']);
        expect(subject.states, <GuestsState>[
          const GuestsState(loadStatus: RequestStatus.loading),
          GuestsState(
            loadStatus: RequestStatus.success,
            directory: testGuestDirectory(),
          ),
        ]);
      },
    );

    test(
      'a failed first load reports the failure without a directory',
      () async {
        final _Subject subject = _Subject();
        addTearDown(subject.bloc.close);
        subject.repository.directoryResult =
            const Left<Failure, GuestDirectoryEntity>(_failure);

        subject.bloc.add(const GuestsRequested());
        await pumpEventQueue();

        expect(subject.states, <GuestsState>[
          const GuestsState(loadStatus: RequestStatus.loading),
          const GuestsState(
            loadStatus: RequestStatus.failure,
            loadFailure: _failure,
          ),
        ]);
      },
    );

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.directoryResult =
          const Left<Failure, GuestDirectoryEntity>(_failure);
      subject.bloc.add(const GuestsRequested());
      await pumpEventQueue();
      subject.states.clear();
      subject.repository.directoryResult = Right<Failure, GuestDirectoryEntity>(
        testGuestDirectory(),
      );

      subject.bloc.add(const GuestsRequested());
      await pumpEventQueue();

      expect(subject.states, <GuestsState>[
        const GuestsState(loadStatus: RequestStatus.loading),
        GuestsState(
          loadStatus: RequestStatus.success,
          directory: testGuestDirectory(),
        ),
      ]);
    });

    test('a failed refresh keeps the directory', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.bloc.add(const GuestsRequested());
      await pumpEventQueue();
      subject.states.clear();
      subject.repository.directoryResult =
          const Left<Failure, GuestDirectoryEntity>(_failure);

      subject.bloc.add(const GuestsRequested());
      await pumpEventQueue();

      expect(subject.states, <GuestsState>[
        GuestsState(
          loadStatus: RequestStatus.loading,
          directory: testGuestDirectory(),
        ),
        GuestsState(
          loadStatus: RequestStatus.failure,
          directory: testGuestDirectory(),
          loadFailure: _failure,
        ),
      ]);
      expect(subject.bloc.state.hasLoaded, isTrue);
    });

    testWidgets('typing runs one search after the debounce', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      subject.bloc.add(const GuestsQueryChanged('А'));
      await tester.pump(const Duration(milliseconds: 200));
      subject.bloc.add(const GuestsQueryChanged('Ай'));
      await tester.pump(const Duration(milliseconds: 200));
      subject.bloc.add(const GuestsQueryChanged('Айж'));
      await tester.pump(
        GuestsBloc.queryDebounce - const Duration(milliseconds: 1),
      );
      expect(subject.repository.directoryQueries, isEmpty);
      expect(subject.states, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await _flush(tester);

      expect(subject.repository.directoryQueries, <String>['Айж']);
      expect(subject.states, <GuestsState>[
        const GuestsState(query: 'Айж', loadStatus: RequestStatus.loading),
        GuestsState(
          query: 'Айж',
          loadStatus: RequestStatus.success,
          directory: testGuestDirectory(),
        ),
      ]);
      expect(subject.bloc.state.isSearching, isTrue);

      await _close(tester, subject.bloc);
    });

    testWidgets('the query is trimmed before the search', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      await _search(tester, subject, '  Айжан  ');

      expect(subject.repository.directoryQueries, <String>['Айжан']);
      expect(subject.bloc.state.query, 'Айжан');

      await _close(tester, subject.bloc);
    });

    testWidgets('a search keeps the shown directory while it loads', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.bloc.add(const GuestsRequested());
      await _flush(tester);
      subject.repository.holdDirectory = true;

      await _search(tester, subject, 'samal');

      expect(
        subject.bloc.state,
        GuestsState(
          query: 'samal',
          loadStatus: RequestStatus.loading,
          directory: testGuestDirectory(),
        ),
      );

      subject.repository.heldDirectory.single.complete(
        Right<Failure, GuestDirectoryEntity>(_directoryFor('samal')),
      );
      await _flush(tester);
      expect(subject.bloc.state.directory, _directoryFor('samal'));

      await _close(tester, subject.bloc);
    });

    testWidgets('the current query is not requested again after success', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.bloc.add(const GuestsRequested());
      await _flush(tester);
      subject.states.clear();

      await _search(tester, subject, '   ');

      expect(subject.repository.directoryQueries, <String>['']);
      expect(subject.states, isEmpty);

      await _close(tester, subject.bloc);
    });

    testWidgets('the current query is not requested again while it loads', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdDirectory = true;
      await _search(tester, subject, 'samal');

      await _search(tester, subject, 'samal ');

      expect(subject.repository.directoryQueries, <String>['samal']);

      await _close(tester, subject.bloc);
    });

    testWidgets('the current query is requested again after a failure', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.directoryResult =
          const Left<Failure, GuestDirectoryEntity>(_failure);
      await _search(tester, subject, 'samal');
      expect(subject.bloc.state.loadStatus, RequestStatus.failure);
      subject.repository.directoryResult = Right<Failure, GuestDirectoryEntity>(
        _directoryFor('samal'),
      );

      await _search(tester, subject, 'samal');

      expect(subject.repository.directoryQueries, <String>['samal', 'samal']);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.loadFailure, isNull);

      await _close(tester, subject.bloc);
    });

    testWidgets('an older search finishing last does not replace a newer one', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdDirectory = true;
      await _search(tester, subject, 'a');
      await _search(tester, subject, 'b');
      expect(subject.repository.directoryQueries, <String>['a', 'b']);

      subject.repository.heldDirectory[1].complete(
        Right<Failure, GuestDirectoryEntity>(_directoryFor('b')),
      );
      await _flush(tester);
      subject.repository.heldDirectory[0].complete(
        Right<Failure, GuestDirectoryEntity>(_directoryFor('a')),
      );
      await _flush(tester);

      expect(
        subject.bloc.state,
        GuestsState(
          query: 'b',
          loadStatus: RequestStatus.success,
          directory: _directoryFor('b'),
        ),
      );

      await _close(tester, subject.bloc);
    });

    testWidgets('a refresh finishing after a newer search is dropped', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdDirectory = true;
      subject.bloc.add(const GuestsRequested());
      await _flush(tester);
      await _search(tester, subject, 'b');
      subject.states.clear();

      // The stale refresh completes first: nothing is emitted.
      subject.repository.heldDirectory[0].complete(
        const Left<Failure, GuestDirectoryEntity>(_failure),
      );
      await _flush(tester);
      expect(subject.states, isEmpty);
      expect(subject.bloc.state.loadStatus, RequestStatus.loading);

      subject.repository.heldDirectory[1].complete(
        Right<Failure, GuestDirectoryEntity>(_directoryFor('b')),
      );
      await _flush(tester);

      expect(subject.states, <GuestsState>[
        GuestsState(
          query: 'b',
          loadStatus: RequestStatus.success,
          directory: _directoryFor('b'),
        ),
      ]);

      await _close(tester, subject.bloc);
    });

    testWidgets('a search finishing after a newer refresh is dropped', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdDirectory = true;
      await _search(tester, subject, 'a');
      subject.bloc.add(const GuestsRequested());
      await _flush(tester);
      expect(subject.repository.directoryQueries, <String>['a', 'a']);

      subject.repository.heldDirectory[1].complete(
        Right<Failure, GuestDirectoryEntity>(_directoryFor('a')),
      );
      await _flush(tester);
      subject.repository.heldDirectory[0].complete(
        const Left<Failure, GuestDirectoryEntity>(_failure),
      );
      await _flush(tester);

      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.loadFailure, isNull);
      expect(subject.bloc.state.directory, _directoryFor('a'));

      await _close(tester, subject.bloc);
    });

    test(
      'closing during an awaited load emits nothing and throws nothing',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdDirectory = true;
        subject.bloc.add(const GuestsRequested());
        await pumpEventQueue();

        await subject.bloc.close();
        subject.repository.heldDirectory.single.complete(
          Right<Failure, GuestDirectoryEntity>(testGuestDirectory()),
        );
        await pumpEventQueue();

        expect(subject.states, <GuestsState>[
          const GuestsState(loadStatus: RequestStatus.loading),
        ]);
      },
    );

    testWidgets('closing during the debounce starts no search', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      subject.bloc.add(const GuestsQueryChanged('samal'));
      await tester.pump(const Duration(milliseconds: 100));
      await _close(tester, subject.bloc);
      await tester.pump(GuestsBloc.queryDebounce);

      expect(subject.repository.directoryQueries, isEmpty);
      expect(subject.states, isEmpty);
    });
  });
}
