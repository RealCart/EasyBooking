import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/upcoming_stay_entity.dart';

/// An apartment the user manages.
final class PropertyEntity extends Equatable {
  const PropertyEntity({
    required this.id,
    required this.name,
    required this.unit,
    required this.city,
    required this.address,
    required this.rooms,
    required this.areaSqm,
    required this.maxGuests,
    required this.pricePerNight,
    required this.imageUrls,
    required this.channelNames,
    required this.syncedAt,
    required this.availability,
    required this.isFavorite,
    required this.receivedAt,
    this.upcomingStay,
  });

  final String id;

  /// Building or complex, such as `Esentai City`.
  final String name;

  /// Apartment number within [name], such as `84`.
  final String unit;
  final String city;
  final String address;
  final int rooms;
  final int areaSqm;
  final int maxGuests;

  /// Base price in whole tenge.
  final int pricePerNight;

  /// Photos, the cover first; never empty.
  final List<String> imageUrls;

  /// Connected booking channels, such as `Airbnb`.
  final List<String> channelNames;

  /// When the channel calendars were last imported.
  final DateTime syncedAt;
  final PropertyAvailabilityEntity availability;
  final bool isFavorite;

  /// The source's current time when it answered: the reference for
  /// relative labels («Обновлены сегодня, 09:38»).
  final DateTime receivedAt;

  /// The next arriving guest; `null` when nobody is booked.
  final UpcomingStayEntity? upcomingStay;

  PropertyEntity copyWith({bool? isFavorite, DateTime? receivedAt}) {
    return PropertyEntity(
      id: id,
      name: name,
      unit: unit,
      city: city,
      address: address,
      rooms: rooms,
      areaSqm: areaSqm,
      maxGuests: maxGuests,
      pricePerNight: pricePerNight,
      imageUrls: imageUrls,
      channelNames: channelNames,
      syncedAt: syncedAt,
      availability: availability,
      isFavorite: isFavorite ?? this.isFavorite,
      receivedAt: receivedAt ?? this.receivedAt,
      upcomingStay: upcomingStay,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    unit,
    city,
    address,
    rooms,
    areaSqm,
    maxGuests,
    pricePerNight,
    imageUrls,
    channelNames,
    syncedAt,
    availability,
    isFavorite,
    receivedAt,
    upcomingStay,
  ];
}
