import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

/// Input of `InviteTeamMemberUsecase`: the «Пригласить участника» form.
final class InviteTeamMemberParamsEntity extends Equatable {
  const InviteTeamMemberParamsEntity({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
  });

  final String firstName;
  final String lastName;

  /// Any phone input; the use case normalizes it to E.164.
  final String phone;

  /// Any role except [ProfileRole.owner].
  final ProfileRole role;

  @override
  List<Object?> get props => <Object?>[firstName, lastName, phone, role];
}
