import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/presentation/widgets/property_labels.dart';

import '../../../../helpers/fake_properties_repository.dart';

PropertyEntity _property({required int areaSqm, int rooms = 2}) {
  final PropertyEntity base = testProperties().first;
  return PropertyEntity(
    id: base.id,
    name: base.name,
    unit: base.unit,
    city: base.city,
    address: base.address,
    rooms: rooms,
    areaSqm: areaSqm,
    maxGuests: rooms * 2,
    pricePerNight: base.pricePerNight,
    imageUrls: base.imageUrls,
    channelNames: base.channelNames,
    syncedAt: base.syncedAt,
    availability: const PropertyAvailabilityEntity(
      kind: PropertyAvailabilityKind.free,
    ),
    isFavorite: false,
    receivedAt: base.receivedAt,
  );
}

void main() {
  group('PropertyLabels.specs', () {
    test('lists rooms, area, and guests', () {
      expect(_property(areaSqm: 54).specs, '2 комнаты · 54 м² · до 4 гостей');
    });

    test('leaves the area out when it is unknown (0)', () {
      expect(_property(areaSqm: 0).specs, '2 комнаты · до 4 гостей');
      expect(
        _property(areaSqm: 0, rooms: 1).specs,
        '1 комната · до 2 гостей',
      );
    });
  });
}
