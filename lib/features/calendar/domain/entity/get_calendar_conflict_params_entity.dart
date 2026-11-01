import 'package:equatable/equatable.dart';

final class GetCalendarConflictParamsEntity extends Equatable {
  const GetCalendarConflictParamsEntity({required this.conflictId});

  final String conflictId;

  @override
  List<Object?> get props => <Object?>[conflictId];
}
