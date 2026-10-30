import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';

/// Cities offered on account setup.
///
/// Kazakhstan has used a single UTC+5 zone since 2024, so every city has the
/// same offset; the IANA ids still differ by region.
abstract final class KazakhstanCities {
  static const Duration _utcOffset = Duration(hours: 5);

  static const CityEntity almaty = CityEntity(
    id: 'almaty',
    name: 'Алматы',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity astana = CityEntity(
    id: 'astana',
    name: 'Астана',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity shymkent = CityEntity(
    id: 'shymkent',
    name: 'Шымкент',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity karaganda = CityEntity(
    id: 'karaganda',
    name: 'Караганда',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity aktobe = CityEntity(
    id: 'aktobe',
    name: 'Актобе',
    timeZone: 'Asia/Aqtobe',
    utcOffset: _utcOffset,
  );

  static const CityEntity taraz = CityEntity(
    id: 'taraz',
    name: 'Тараз',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity pavlodar = CityEntity(
    id: 'pavlodar',
    name: 'Павлодар',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity ustKamenogorsk = CityEntity(
    id: 'ust_kamenogorsk',
    name: 'Усть-Каменогорск',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity semey = CityEntity(
    id: 'semey',
    name: 'Семей',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity atyrau = CityEntity(
    id: 'atyrau',
    name: 'Атырау',
    timeZone: 'Asia/Atyrau',
    utcOffset: _utcOffset,
  );

  static const CityEntity kostanay = CityEntity(
    id: 'kostanay',
    name: 'Костанай',
    timeZone: 'Asia/Qostanay',
    utcOffset: _utcOffset,
  );

  static const CityEntity kyzylorda = CityEntity(
    id: 'kyzylorda',
    name: 'Кызылорда',
    timeZone: 'Asia/Qyzylorda',
    utcOffset: _utcOffset,
  );

  static const CityEntity uralsk = CityEntity(
    id: 'uralsk',
    name: 'Уральск',
    timeZone: 'Asia/Oral',
    utcOffset: _utcOffset,
  );

  static const CityEntity petropavlovsk = CityEntity(
    id: 'petropavlovsk',
    name: 'Петропавловск',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity aktau = CityEntity(
    id: 'aktau',
    name: 'Актау',
    timeZone: 'Asia/Aqtau',
    utcOffset: _utcOffset,
  );

  static const CityEntity turkestan = CityEntity(
    id: 'turkestan',
    name: 'Туркестан',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity taldykorgan = CityEntity(
    id: 'taldykorgan',
    name: 'Талдыкорган',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity kokshetau = CityEntity(
    id: 'kokshetau',
    name: 'Кокшетау',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const CityEntity konaev = CityEntity(
    id: 'konaev',
    name: 'Конаев',
    timeZone: 'Asia/Almaty',
    utcOffset: _utcOffset,
  );

  static const List<CityEntity> all = <CityEntity>[
    almaty,
    astana,
    shymkent,
    karaganda,
    aktobe,
    taraz,
    pavlodar,
    ustKamenogorsk,
    semey,
    atyrau,
    kostanay,
    kyzylorda,
    uralsk,
    petropavlovsk,
    aktau,
    turkestan,
    taldykorgan,
    kokshetau,
    konaev,
  ];
}
