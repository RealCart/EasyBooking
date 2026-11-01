import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

enum TeamMemberStatus {
  active,

  /// Invited, but has not accepted yet.
  invited,
}

/// A member of the workspace team on «Команда и доступ».
final class TeamMemberEntity extends Equatable {
  const TeamMemberEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.propertyCount,
    required this.hasAllProperties,
    required this.isCurrentUser,
    this.status = TeamMemberStatus.active,
    this.inviteExpiresAt,
  });

  final String id;
  final String firstName;
  final String lastName;

  /// E.164, such as `+77012345678`.
  final String phone;
  final ProfileRole role;

  /// Properties the member can access; see [hasAllProperties].
  final int propertyCount;

  /// Access to every property, present and future (the owner).
  final bool hasAllProperties;

  /// The signed-in user; cannot be removed.
  final bool isCurrentUser;
  final TeamMemberStatus status;

  /// When the invitation stops working; set while [status] is
  /// [TeamMemberStatus.invited].
  final DateTime? inviteExpiresAt;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => <Object?>[
    id,
    firstName,
    lastName,
    phone,
    role,
    propertyCount,
    hasAllProperties,
    isCurrentUser,
    status,
    inviteExpiresAt,
  ];
}
