part of 'property_detail_bloc.dart';

final class PropertyDetailState extends Equatable {
  const PropertyDetailState({
    this.propertyId = '',
    this.loadStatus = RequestStatus.initial,
    this.property,
    this.loadFailure,
    this.favoriteFailure,
  });

  /// The requested property, for retrying a failed load.
  final String propertyId;

  final RequestStatus loadStatus;
  final PropertyEntity? property;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// The failure of the last favorite write, for a one-off message.
  final Failure? favoriteFailure;

  PropertyDetailState copyWith({
    String? propertyId,
    RequestStatus? loadStatus,
    PropertyEntity? property,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    Failure? favoriteFailure,
    bool resetFavoriteFailure = false,
  }) {
    return PropertyDetailState(
      propertyId: propertyId ?? this.propertyId,
      loadStatus: loadStatus ?? this.loadStatus,
      property: property ?? this.property,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      favoriteFailure: resetFavoriteFailure
          ? null
          : favoriteFailure ?? this.favoriteFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    loadStatus,
    property,
    loadFailure,
    favoriteFailure,
  ];
}
