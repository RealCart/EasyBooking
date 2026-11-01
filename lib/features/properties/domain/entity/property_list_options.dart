import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// The availability chips above the property list.
enum PropertiesFilter {
  all,
  free,
  busy;

  bool matches(PropertyEntity property) {
    return switch (this) {
      PropertiesFilter.all => true,
      PropertiesFilter.free => !property.availability.isBusy,
      PropertiesFilter.busy => property.availability.isBusy,
    };
  }
}

enum PropertySort {
  /// The source order: what needs attention first.
  recommended,
  priceLow,
  priceHigh;

  /// [properties] in this order; a new list.
  List<PropertyEntity> sorted(List<PropertyEntity> properties) {
    final List<PropertyEntity> result = List<PropertyEntity>.of(properties);
    switch (this) {
      case PropertySort.recommended:
        break;
      case PropertySort.priceLow:
        result.sort(
          (PropertyEntity a, PropertyEntity b) =>
              a.pricePerNight.compareTo(b.pricePerNight),
        );
      case PropertySort.priceHigh:
        result.sort(
          (PropertyEntity a, PropertyEntity b) =>
              b.pricePerNight.compareTo(a.pricePerNight),
        );
    }
    return result;
  }
}

extension PropertySearch on PropertyEntity {
  /// Whether [query] occurs in the name, the unit, or the address, ignoring
  /// case and surrounding spaces. An empty query matches everything.
  bool matchesQuery(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return '$name $unit $address'.toLowerCase().contains(needle);
  }
}
