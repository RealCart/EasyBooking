part of 'properties_bloc.dart';

final class PropertiesState extends Equatable {
  const PropertiesState({
    this.loadStatus = RequestStatus.initial,
    this.properties = const <PropertyEntity>[],
    this.loadFailure,
    this.filter = PropertiesFilter.all,
    this.query = '',
    this.sort = PropertySort.recommended,
    this.favoriteFailure,
  });

  final RequestStatus loadStatus;

  /// Every loaded property in source order; kept while a refresh runs or
  /// after it fails.
  final List<PropertyEntity> properties;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final PropertiesFilter filter;
  final String query;
  final PropertySort sort;

  /// The failure of the last favorite write, for a one-off message.
  /// Cleared when the next write starts.
  final Failure? favoriteFailure;

  bool get hasLoaded => loadStatus.isSuccess || properties.isNotEmpty;

  /// The properties that pass [filter] and [query], in [sort] order.
  List<PropertyEntity> get visibleProperties {
    return List<PropertyEntity>.unmodifiable(
      sort.sorted(<PropertyEntity>[
        for (final PropertyEntity property in properties)
          if (filter.matches(property) && property.matchesQuery(query))
            property,
      ]),
    );
  }

  List<PropertyEntity> get favorites {
    return List<PropertyEntity>.unmodifiable(
      properties.where((PropertyEntity property) => property.isFavorite),
    );
  }

  /// How many properties the chip [filter] would show, ignoring [query].
  int countFor(PropertiesFilter filter) {
    return properties.where(filter.matches).length;
  }

  PropertyEntity? propertyById(String id) {
    for (final PropertyEntity property in properties) {
      if (property.id == id) {
        return property;
      }
    }
    return null;
  }

  PropertiesState copyWith({
    RequestStatus? loadStatus,
    List<PropertyEntity>? properties,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    PropertiesFilter? filter,
    String? query,
    PropertySort? sort,
    Failure? favoriteFailure,
    bool resetFavoriteFailure = false,
  }) {
    return PropertiesState(
      loadStatus: loadStatus ?? this.loadStatus,
      properties: properties ?? this.properties,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      favoriteFailure: resetFavoriteFailure
          ? null
          : favoriteFailure ?? this.favoriteFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    properties,
    loadFailure,
    filter,
    query,
    sort,
    favoriteFailure,
  ];
}
