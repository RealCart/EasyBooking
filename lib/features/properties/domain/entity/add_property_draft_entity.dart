import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';

/// The property being added, kept by the source between the steps of
/// «Добавить квартиру». A fresh draft holds the source's defaults.
final class AddPropertyDraftEntity extends Equatable {
  const AddPropertyDraftEntity({
    required this.title,
    required this.address,
    required this.type,
    required this.rooms,
    required this.channels,
    required this.terms,
  });

  /// As typed on step 1, such as `Esentai City · 84`; empty until saved.
  final String title;

  /// Empty until step 1 is saved.
  final String address;
  final PropertyType type;
  final int rooms;

  /// Channels chosen on step 2, in the order they were chosen.
  final List<BookingChannel> channels;

  /// The values step 3 starts with.
  final PropertyTermsEntity terms;

  /// Whether step 1 was saved, so the property can be published.
  bool get hasDetails {
    return Validators.isNotBlank(title) && Validators.isNotBlank(address);
  }

  @override
  List<Object?> get props => <Object?>[
    title,
    address,
    type,
    rooms,
    channels,
    terms,
  ];
}
