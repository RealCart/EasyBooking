import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_list_options.dart';

import '../../../../helpers/fake_properties_repository.dart';

void main() {
  final List<PropertyEntity> properties = testProperties();

  List<String> ids(Iterable<PropertyEntity> properties) {
    return <String>[
      for (final PropertyEntity property in properties) property.id,
    ];
  }

  group('PropertiesFilter', () {
    test('splits busy and free properties', () {
      expect(ids(properties.where(PropertiesFilter.all.matches)), <String>[
        'p1',
        'p2',
      ]);
      expect(ids(properties.where(PropertiesFilter.busy.matches)), <String>[
        'p1',
      ]);
      expect(ids(properties.where(PropertiesFilter.free.matches)), <String>[
        'p2',
      ]);
    });
  });

  group('PropertySort', () {
    test('sorts by price without changing the input', () {
      expect(ids(PropertySort.priceLow.sorted(properties)), <String>[
        'p2',
        'p1',
      ]);
      expect(ids(PropertySort.priceHigh.sorted(properties)), <String>[
        'p1',
        'p2',
      ]);
      expect(ids(PropertySort.recommended.sorted(properties)), <String>[
        'p1',
        'p2',
      ]);
      expect(ids(properties), <String>['p1', 'p2']);
    });
  });

  group('matchesQuery', () {
    test('matches the name, unit, or address ignoring case and spaces', () {
      expect(properties[0].matchesQuery('  esentai '), isTrue);
      expect(properties[1].matchesQuery('126'), isTrue);
      expect(properties[1].matchesQuery('каблукова'), isTrue);
      expect(properties[0].matchesQuery('mega'), isFalse);
      expect(properties[0].matchesQuery(''), isTrue);
    });
  });
}
