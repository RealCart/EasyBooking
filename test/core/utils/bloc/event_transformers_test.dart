import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';

final class _Load {
  const _Load(this.id);

  final String id;
}

/// Each handler waits until the test completes the request for its id, then
/// emits the result without checking `emit.isDone`, so only the transformer
/// and the BLoC cancellation can suppress a stale emission.
final class _RequestBloc extends Bloc<_Load, String> {
  _RequestBloc(EventTransformer<_Load> transformer) : super('initial') {
    on<_Load>(_onLoad, transformer: transformer);
  }

  final List<String> started = <String>[];
  final List<String> finished = <String>[];
  final List<Object> errors = <Object>[];
  final Map<String, Completer<String>> _pending = <String, Completer<String>>{};

  void complete(String id, [String? result]) {
    _pending[id]!.complete(result ?? 'result:$id');
  }

  Future<void> _onLoad(_Load event, Emitter<String> emit) async {
    started.add(event.id);
    final Completer<String> completer = Completer<String>();
    _pending[event.id] = completer;
    final String result = await completer.future;
    finished.add(event.id);
    emit(result);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(error, stackTrace);
  }
}

/// Records every state the bloc emits after creation.
List<String> _record(_RequestBloc bloc) {
  final List<String> states = <String>[];
  final StreamSubscription<String> subscription = bloc.stream.listen(
    states.add,
  );
  addTearDown(subscription.cancel);
  return states;
}

/// Starts closing [bloc] inside a `testWidgets` fake-async zone.
///
/// The future returned by `Bloc.close` does not complete under the widget
/// tester's fake async, so it is not awaited; pumping flushes the close.
Future<void> _closeInFakeAsync(WidgetTester tester, _RequestBloc bloc) async {
  unawaited(bloc.close());
  await tester.pump();
  expect(bloc.isClosed, isTrue);
}

void main() {
  group('restartable', () {
    late _RequestBloc bloc;

    setUp(() => bloc = _RequestBloc(restartable<_Load>()));
    tearDown(() => bloc.close());

    test('a stale response A never replaces the newer response B', () async {
      final List<String> states = _record(bloc);

      bloc
        ..add(const _Load('A'))
        ..add(const _Load('B'));
      await pumpEventQueue();
      expect(bloc.started, <String>['A', 'B']);

      bloc.complete('B');
      await pumpEventQueue();
      bloc.complete('A');
      await pumpEventQueue();

      expect(states, <String>['result:B']);
      expect(bloc.state, 'result:B');
      expect(bloc.finished, <String>['B', 'A']);
    });

    test('a request that finishes before the next one is emitted', () async {
      final List<String> states = _record(bloc);

      bloc.add(const _Load('A'));
      await pumpEventQueue();
      bloc.complete('A');
      await pumpEventQueue();
      bloc.add(const _Load('B'));
      await pumpEventQueue();
      bloc.complete('B');
      await pumpEventQueue();

      expect(states, <String>['result:A', 'result:B']);
    });

    test(
      'closing during an awaited handler emits nothing and throws nothing',
      () async {
        final List<String> states = _record(bloc);

        bloc.add(const _Load('A'));
        await pumpEventQueue();
        await bloc.close();
        bloc.complete('A');
        await pumpEventQueue();

        expect(bloc.isClosed, isTrue);
        expect(states, isEmpty);
        expect(bloc.errors, isEmpty);
      },
    );
  });

  group('droppable', () {
    late _RequestBloc bloc;

    setUp(() => bloc = _RequestBloc(droppable<_Load>()));
    tearDown(() => bloc.close());

    test('ignores an event that arrives while a handler is running', () async {
      final List<String> states = _record(bloc);

      bloc
        ..add(const _Load('A'))
        ..add(const _Load('B'));
      await pumpEventQueue();
      expect(bloc.started, <String>['A']);

      bloc.complete('A');
      await pumpEventQueue();

      expect(states, <String>['result:A']);
      expect(bloc.started, <String>['A']);
    });

    test('accepts a new event after the running handler finishes', () async {
      final List<String> states = _record(bloc);

      bloc.add(const _Load('A'));
      await pumpEventQueue();
      bloc.complete('A');
      await pumpEventQueue();
      bloc.add(const _Load('C'));
      await pumpEventQueue();
      bloc.complete('C');
      await pumpEventQueue();

      expect(bloc.started, <String>['A', 'C']);
      expect(states, <String>['result:A', 'result:C']);
    });

    test(
      'closing during an awaited handler emits nothing and throws nothing',
      () async {
        final List<String> states = _record(bloc);

        bloc.add(const _Load('A'));
        await pumpEventQueue();
        await bloc.close();
        bloc.complete('A');
        await pumpEventQueue();

        expect(states, isEmpty);
        expect(bloc.errors, isEmpty);
      },
    );
  });

  group('sequential', () {
    late _RequestBloc bloc;

    setUp(() => bloc = _RequestBloc(sequential<_Load>()));
    tearDown(() => bloc.close());

    test('handles events one at a time in arrival order', () async {
      final List<String> states = _record(bloc);

      bloc
        ..add(const _Load('A'))
        ..add(const _Load('B'))
        ..add(const _Load('C'));
      await pumpEventQueue();
      expect(bloc.started, <String>['A']);

      bloc.complete('A');
      await pumpEventQueue();
      expect(bloc.started, <String>['A', 'B']);

      bloc.complete('B');
      await pumpEventQueue();
      bloc.complete('C');
      await pumpEventQueue();

      expect(bloc.started, <String>['A', 'B', 'C']);
      expect(states, <String>['result:A', 'result:B', 'result:C']);
    });

    test(
      'closing during an awaited handler emits nothing and throws nothing',
      () async {
        final List<String> states = _record(bloc);

        bloc.add(const _Load('A'));
        await pumpEventQueue();
        final Future<void> closing = bloc.close();
        await pumpEventQueue();
        bloc.complete('A');
        await closing;
        await pumpEventQueue();

        expect(bloc.isClosed, isTrue);
        expect(states, isEmpty);
        expect(bloc.errors, isEmpty);
      },
    );

    test(
      'closing with a queued event does not start the queued handler',
      () async {
        final List<String> states = _record(bloc);

        bloc
          ..add(const _Load('A'))
          ..add(const _Load('B'));
        await pumpEventQueue();
        final Future<void> closing = bloc.close();
        await pumpEventQueue();
        bloc.complete('A');
        await pumpEventQueue();
        final List<String> startedAfterClose = List<String>.of(bloc.started);
        final List<String> statesAfterClose = List<String>.of(states);

        // Release a queued handler if one was started, so close() can finish
        // and the failure is reported instead of hanging the suite.
        if (bloc.started.contains('B')) {
          bloc.complete('B');
        }
        await closing;

        expect(startedAfterClose, <String>['A']);
        expect(statesAfterClose, isEmpty);
        expect(states, isEmpty);
      },
    );
  });

  group('debounceRestartable', () {
    const Duration window = Duration(milliseconds: 300);

    testWidgets('handles only the last event within the window', (
      WidgetTester tester,
    ) async {
      final _RequestBloc bloc = _RequestBloc(
        debounceRestartable<_Load>(window),
      );

      bloc.add(const _Load('a'));
      await tester.pump(const Duration(milliseconds: 100));
      bloc.add(const _Load('ab'));
      await tester.pump(const Duration(milliseconds: 100));
      bloc.add(const _Load('abc'));
      await tester.pump(const Duration(milliseconds: 299));
      expect(bloc.started, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(bloc.started, <String>['abc']);

      await _closeInFakeAsync(tester, bloc);
    });

    testWidgets('events separated by more than the window are all handled', (
      WidgetTester tester,
    ) async {
      final _RequestBloc bloc = _RequestBloc(
        debounceRestartable<_Load>(window),
      );
      final List<String> states = _record(bloc);

      bloc.add(const _Load('a'));
      await tester.pump(window);
      bloc.complete('a');
      await tester.pump();
      bloc.add(const _Load('b'));
      await tester.pump(window);
      bloc.complete('b');
      await tester.pump();

      expect(bloc.started, <String>['a', 'b']);
      expect(states, <String>['result:a', 'result:b']);

      await _closeInFakeAsync(tester, bloc);
    });

    testWidgets('a newer debounced request wins over a stale running one', (
      WidgetTester tester,
    ) async {
      final _RequestBloc bloc = _RequestBloc(
        debounceRestartable<_Load>(window),
      );
      final List<String> states = _record(bloc);

      bloc.add(const _Load('a'));
      await tester.pump(window);
      bloc.add(const _Load('b'));
      await tester.pump(window);
      expect(bloc.started, <String>['a', 'b']);

      bloc.complete('b');
      await tester.pump();
      bloc.complete('a');
      await tester.pump();

      expect(states, <String>['result:b']);

      await _closeInFakeAsync(tester, bloc);
    });

    testWidgets('a pending debounced event is dropped on close', (
      WidgetTester tester,
    ) async {
      final _RequestBloc bloc = _RequestBloc(
        debounceRestartable<_Load>(window),
      );

      bloc.add(const _Load('a'));
      await tester.pump(const Duration(milliseconds: 100));
      await _closeInFakeAsync(tester, bloc);
      await tester.pump(window * 2);

      expect(bloc.started, isEmpty);
      expect(bloc.errors, isEmpty);
    });

    testWidgets('closing during an awaited handler emits nothing', (
      WidgetTester tester,
    ) async {
      final _RequestBloc bloc = _RequestBloc(
        debounceRestartable<_Load>(window),
      );
      final List<String> states = _record(bloc);

      bloc.add(const _Load('a'));
      await tester.pump(window);
      expect(bloc.started, <String>['a']);

      await _closeInFakeAsync(tester, bloc);
      bloc.complete('a');
      await tester.pump();

      expect(states, isEmpty);
      expect(bloc.errors, isEmpty);
    });
  });
}
