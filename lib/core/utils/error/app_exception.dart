/// Exceptions thrown by data sources and converted to a `Failure` at the
/// repository boundary by `mapExceptionToFailure`.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// External data (JSON, stored value) did not have the expected shape.
final class ParsingException extends AppException {
  const ParsingException(super.message);
}

/// A local storage operation failed.
final class StorageException extends AppException {
  const StorageException(super.message);
}
