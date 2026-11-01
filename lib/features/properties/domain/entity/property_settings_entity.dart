import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';

/// What the property's «Настройки» tab summarizes.
final class PropertySettingsEntity extends Equatable {
  const PropertySettingsEntity({
    required this.property,
    required this.type,
    required this.terms,
    required this.houseRules,
    required this.channelErrorCount,
    required this.teamMemberCount,
    required this.guestInstructionTopics,
    required this.acceptsBookings,
  });

  /// Name, unit, photos, and connected channels.
  final PropertyEntity property;
  final PropertyType type;

  /// Price, deposit, check-in and check-out times.
  final PropertyTermsEntity terms;

  /// Short rules, such as `Не курить`; may be empty.
  final List<String> houseRules;

  /// Connected channels whose last calendar import failed.
  final int channelErrorCount;

  /// People of the team with access to the property, the owner included.
  final int teamMemberCount;

  /// Filled-in guest instruction sections, such as `Домофон`; may be empty.
  final List<String> guestInstructionTopics;

  /// Whether the property takes new bookings on all channels («Активен»).
  final bool acceptsBookings;

  @override
  List<Object?> get props => <Object?>[
    property,
    type,
    terms,
    houseRules,
    channelErrorCount,
    teamMemberCount,
    guestInstructionTopics,
    acceptsBookings,
  ];
}
