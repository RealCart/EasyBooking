import 'package:equatable/equatable.dart';

/// A value that is either a [Left] (by convention, a failure) or a [Right]
/// (by convention, a success).
///
/// The branch is identified by the subtype, never by a null payload, so
/// `Either<Failure, void>` and nullable success values are safe.
sealed class Either<L, R> extends Equatable {
  const Either();

  const factory Either.left(L value) = Left<L, R>;

  const factory Either.right(R value) = Right<L, R>;

  bool get isLeft => this is Left<L, R>;

  bool get isRight => this is Right<L, R>;

  /// Calls exactly one of the callbacks and returns its result.
  ///
  /// `fold` does not await anything: when the callbacks are asynchronous, the
  /// caller must await the returned `Future`.
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return switch (this) {
      Left<L, R>(:final L value) => onLeft(value),
      Right<L, R>(:final R value) => onRight(value),
    };
  }

  Either<L, T> map<T>(T Function(R right) transform) {
    return switch (this) {
      Left<L, R>(:final L value) => Left<L, T>(value),
      Right<L, R>(:final R value) => Right<L, T>(transform(value)),
    };
  }

  Either<T, R> mapLeft<T>(T Function(L left) transform) {
    return switch (this) {
      Left<L, R>(:final L value) => Left<T, R>(transform(value)),
      Right<L, R>(:final R value) => Right<T, R>(value),
    };
  }

  Either<L, T> flatMap<T>(Either<L, T> Function(R right) transform) {
    return switch (this) {
      Left<L, R>(:final L value) => Left<L, T>(value),
      Right<L, R>(:final R value) => transform(value),
    };
  }

  /// Like [flatMap] for an asynchronous next step: runs [transform] only on
  /// a [Right] and completes with its result; a [Left] is passed through.
  Future<Either<L, T>> flatMapAsync<T>(
    Future<Either<L, T>> Function(R right) transform,
  ) async {
    return switch (this) {
      Left<L, R>(:final L value) => Left<L, T>(value),
      Right<L, R>(:final R value) => transform(value),
    };
  }
}

final class Left<L, R> extends Either<L, R> {
  const Left(this.value);

  final L value;

  @override
  List<Object?> get props => <Object?>[value];
}

final class Right<L, R> extends Either<L, R> {
  const Right(this.value);

  final R value;

  @override
  List<Object?> get props => <Object?>[value];
}
