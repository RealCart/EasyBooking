import 'package:equatable/equatable.dart';

enum ProfileRole {
  /// Full access to every property; one per workspace.
  owner,

  /// Bookings, guests, contracts, and prices of the assigned properties.
  manager,

  /// «Оператор заселения»: guest contacts, arrival time, and instructions.
  checkInOperator,

  /// «Уборка»: only the checkout calendar and property readiness.
  cleaner,
}

enum SubscriptionPlan { free, pro }

/// The signed-in user and a summary of their workspace.
final class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.city,
    required this.propertyCount,
    required this.teamMemberCount,
    required this.plan,
  });

  final String firstName;
  final String lastName;
  final ProfileRole role;

  /// City name, such as `Алматы`.
  final String city;
  final int propertyCount;

  /// Team members other than the user.
  final int teamMemberCount;
  final SubscriptionPlan plan;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    role,
    city,
    propertyCount,
    teamMemberCount,
    plan,
  ];
}
