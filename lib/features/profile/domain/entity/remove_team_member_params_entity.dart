import 'package:equatable/equatable.dart';

final class RemoveTeamMemberParamsEntity extends Equatable {
  const RemoveTeamMemberParamsEntity({required this.memberId});

  final String memberId;

  @override
  List<Object?> get props => <Object?>[memberId];
}
