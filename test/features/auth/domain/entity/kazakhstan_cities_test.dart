import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';

void main() {
  group('KazakhstanCities', () {
    test('lists the 19 cities in display order with their slugs', () {
      expect(
        KazakhstanCities.all.map((CityEntity city) => (city.id, city.name)),
        <(String, String)>[
          ('almaty', 'Алматы'),
          ('astana', 'Астана'),
          ('shymkent', 'Шымкент'),
          ('karaganda', 'Караганда'),
          ('aktobe', 'Актобе'),
          ('taraz', 'Тараз'),
          ('pavlodar', 'Павлодар'),
          ('ust_kamenogorsk', 'Усть-Каменогорск'),
          ('semey', 'Семей'),
          ('atyrau', 'Атырау'),
          ('kostanay', 'Костанай'),
          ('kyzylorda', 'Кызылорда'),
          ('uralsk', 'Уральск'),
          ('petropavlovsk', 'Петропавловск'),
          ('aktau', 'Актау'),
          ('turkestan', 'Туркестан'),
          ('taldykorgan', 'Талдыкорган'),
          ('kokshetau', 'Кокшетау'),
          ('konaev', 'Конаев'),
        ],
      );
    });

    test('every city is UTC+5', () {
      for (final CityEntity city in KazakhstanCities.all) {
        expect(city.utcOffset, const Duration(hours: 5), reason: city.id);
      }
    });

    test('uses the regional IANA zones and Asia/Almaty elsewhere', () {
      const Map<String, String> regional = <String, String>{
        'aktobe': 'Asia/Aqtobe',
        'atyrau': 'Asia/Atyrau',
        'uralsk': 'Asia/Oral',
        'aktau': 'Asia/Aqtau',
        'kyzylorda': 'Asia/Qyzylorda',
        'kostanay': 'Asia/Qostanay',
      };
      for (final CityEntity city in KazakhstanCities.all) {
        expect(
          city.timeZone,
          regional[city.id] ?? 'Asia/Almaty',
          reason: city.id,
        );
      }
    });

    test('ids are unique lowercase Latin slugs', () {
      final Iterable<String> ids = KazakhstanCities.all.map(
        (CityEntity city) => city.id,
      );

      expect(ids.toSet(), hasLength(KazakhstanCities.all.length));
      for (final String id in ids) {
        expect(id, matches(RegExp(r'^[a-z_]+$')));
      }
    });

    test('almaty is the first city', () {
      expect(KazakhstanCities.all.first, same(KazakhstanCities.almaty));
    });
  });
}
