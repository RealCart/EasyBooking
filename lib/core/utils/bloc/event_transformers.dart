import 'dart:async';
import 'dart:collection';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Event transformers for `on<Event>(handler, transformer: ...)`.
///
/// The BLoC default processes events concurrently. Choose one of these when
/// overlapping events need an explicit ordering policy.

/// Handles events one at a time, in arrival order.
///
/// Queued events are dropped when the BLoC closes. Unlike `asyncExpand`, the
/// event stream is never paused, so `close()` does not wait for the queue
/// and the running handler is cancelled like with the other transformers.
EventTransformer<E> sequential<E>() {
  return (Stream<E> events, EventMapper<E> mapper) {
    return _queueMap(events, mapper);
  };
}

/// Ignores new events while a handler is still running.
///
/// Use it for submit actions that must not run twice.
EventTransformer<E> droppable<E>() {
  return (Stream<E> events, EventMapper<E> mapper) {
    return _exhaustMap(events, mapper);
  };
}

/// Cancels the running handler when a new event arrives (latest wins).
///
/// After an `await`, a cancelled handler sees `emit.isDone == true` and its
/// emissions are ignored, so a stale result cannot replace a newer one.
EventTransformer<E> restartable<E>() {
  return (Stream<E> events, EventMapper<E> mapper) {
    return _switchMap(events, mapper);
  };
}

/// Waits until no event arrives for [duration], then handles the latest
/// event as [restartable] does.
///
/// Debounce only reduces how often the handler starts; the restartable part
/// is what protects against stale results.
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return _switchMap(_debounce(events, duration), mapper);
  };
}

Stream<T> _queueMap<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  final StreamController<T> controller = StreamController<T>(sync: true);
  final Queue<S> pending = Queue<S>();
  StreamSubscription<S>? sourceSubscription;
  StreamSubscription<T>? innerSubscription;
  bool isSourceDone = false;

  void startNext() {
    if (innerSubscription != null) {
      return;
    }
    if (pending.isEmpty) {
      if (isSourceDone) {
        controller.close();
      }
      return;
    }
    late final StreamSubscription<T> subscription;
    subscription = mapper(pending.removeFirst()).listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        if (identical(innerSubscription, subscription)) {
          innerSubscription = null;
          startNext();
        }
      },
    );
    innerSubscription = subscription;
  }

  controller
    ..onListen = () {
      sourceSubscription = source.listen(
        (S value) {
          pending.add(value);
          startNext();
        },
        onError: controller.addError,
        onDone: () {
          isSourceDone = true;
          pending.clear();
          startNext();
        },
      );
    }
    ..onPause = () {
      sourceSubscription?.pause();
      innerSubscription?.pause();
    }
    ..onResume = () {
      sourceSubscription?.resume();
      innerSubscription?.resume();
    }
    ..onCancel = () async {
      pending.clear();
      final List<Future<void>> cancellations = <Future<void>>[
        ?sourceSubscription?.cancel(),
        ?innerSubscription?.cancel(),
      ];
      sourceSubscription = null;
      innerSubscription = null;
      await Future.wait(cancellations);
    };

  return controller.stream;
}

Stream<T> _switchMap<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  final StreamController<T> controller = StreamController<T>(sync: true);
  StreamSubscription<S>? sourceSubscription;
  StreamSubscription<T>? innerSubscription;
  bool isSourceDone = false;

  void closeIfDone() {
    if (isSourceDone && innerSubscription == null) {
      controller.close();
    }
  }

  controller
    ..onListen = () {
      sourceSubscription = source.listen(
        (S value) {
          innerSubscription?.cancel();
          late final StreamSubscription<T> subscription;
          subscription = mapper(value).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              if (identical(innerSubscription, subscription)) {
                innerSubscription = null;
                closeIfDone();
              }
            },
          );
          innerSubscription = subscription;
        },
        onError: controller.addError,
        onDone: () {
          isSourceDone = true;
          closeIfDone();
        },
      );
    }
    ..onPause = () {
      sourceSubscription?.pause();
      innerSubscription?.pause();
    }
    ..onResume = () {
      sourceSubscription?.resume();
      innerSubscription?.resume();
    }
    ..onCancel = () async {
      final List<Future<void>> cancellations = <Future<void>>[
        ?sourceSubscription?.cancel(),
        ?innerSubscription?.cancel(),
      ];
      sourceSubscription = null;
      innerSubscription = null;
      await Future.wait(cancellations);
    };

  return controller.stream;
}

Stream<T> _exhaustMap<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  final StreamController<T> controller = StreamController<T>(sync: true);
  StreamSubscription<S>? sourceSubscription;
  StreamSubscription<T>? innerSubscription;
  bool isSourceDone = false;

  void closeIfDone() {
    if (isSourceDone && innerSubscription == null) {
      controller.close();
    }
  }

  controller
    ..onListen = () {
      sourceSubscription = source.listen(
        (S value) {
          if (innerSubscription != null) {
            return;
          }
          late final StreamSubscription<T> subscription;
          subscription = mapper(value).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              if (identical(innerSubscription, subscription)) {
                innerSubscription = null;
                closeIfDone();
              }
            },
          );
          innerSubscription = subscription;
        },
        onError: controller.addError,
        onDone: () {
          isSourceDone = true;
          closeIfDone();
        },
      );
    }
    ..onPause = () {
      sourceSubscription?.pause();
      innerSubscription?.pause();
    }
    ..onResume = () {
      sourceSubscription?.resume();
      innerSubscription?.resume();
    }
    ..onCancel = () async {
      final List<Future<void>> cancellations = <Future<void>>[
        ?sourceSubscription?.cancel(),
        ?innerSubscription?.cancel(),
      ];
      sourceSubscription = null;
      innerSubscription = null;
      await Future.wait(cancellations);
    };

  return controller.stream;
}

/// Pending values are dropped when [source] closes: a closing BLoC must not
/// start a new handler.
Stream<T> _debounce<T>(Stream<T> source, Duration duration) {
  final StreamController<T> controller = StreamController<T>(sync: true);
  StreamSubscription<T>? subscription;
  Timer? timer;

  controller
    ..onListen = () {
      subscription = source.listen(
        (T value) {
          timer?.cancel();
          timer = Timer(duration, () => controller.add(value));
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    }
    ..onPause = () {
      subscription?.pause();
    }
    ..onResume = () {
      subscription?.resume();
    }
    ..onCancel = () async {
      timer?.cancel();
      final Future<void>? cancellation = subscription?.cancel();
      subscription = null;
      await cancellation;
    };

  return controller.stream;
}
