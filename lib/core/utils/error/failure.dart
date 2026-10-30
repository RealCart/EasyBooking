import 'package:equatable/equatable.dart';

/// Expected failure returned through `Either.left`.
///
/// [message] is a technical description for logs. Never show it to users;
/// map the failure type to a localized text in presentation instead.
sealed class Failure extends Equatable {
  const Failure({this.message});

  final String? message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// The device has no connection or the host could not be reached.
final class ConnectionFailure extends Failure {
  const ConnectionFailure({super.message});
}

/// A connect, send, or receive timeout expired.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message});
}

/// The request was cancelled on purpose, usually because it became obsolete.
///
/// Presentation should normally ignore it instead of showing an error.
final class CancelledFailure extends Failure {
  const CancelledFailure({super.message});
}

/// The server rejected the credentials (HTTP 401).
///
/// For an authenticated request the session has been closed. Requests sent
/// before sign-in (for example, a wrong SMS code) keep the session, so the
/// feature should map this failure to its own message.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message});
}

/// The server answered with an error status that has no dedicated failure.
final class ServerFailure extends Failure {
  const ServerFailure({required this.statusCode, this.code, super.message});

  final int? statusCode;

  /// Machine-readable error code from the response body, when present.
  final String? code;

  @override
  List<Object?> get props => <Object?>[statusCode, code, message];
}

/// Input was rejected, either by a use case or by the server (HTTP 400/422).
final class ValidationFailure extends Failure {
  const ValidationFailure({
    this.code,
    this.fieldErrors = const <String, String>{},
    super.message,
  });

  final String? code;

  /// Field name to error description, as reported by the validator.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => <Object?>[code, fieldErrors, message];
}

/// A response or stored value did not have the expected shape.
final class ParsingFailure extends Failure {
  const ParsingFailure({super.message});
}

/// A local storage read or write failed.
final class StorageFailure extends Failure {
  const StorageFailure({super.message});
}

/// An exception that no other failure describes. Always logged.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message});
}
