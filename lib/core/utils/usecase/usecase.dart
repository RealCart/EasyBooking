import 'package:equatable/equatable.dart';

/// Contract for a single application operation.
///
/// [Result] is the complete return type, including `Future` and `Either`,
/// for example `Future<Either<Failure, List<PropertyEntity>>>`.
abstract interface class Usecase<Result, Params> {
  Result call(Params params);
}

/// Parameters of a use case that takes no input. Pass `const NoParams()`.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const <Object?>[];
}
