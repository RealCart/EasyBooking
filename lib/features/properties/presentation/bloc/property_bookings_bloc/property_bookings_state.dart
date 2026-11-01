part of 'property_bookings_bloc.dart';

final class PropertyBookingsState extends Equatable {
  const PropertyBookingsState({
    this.propertyId = '',
    this.loadStatus = RequestStatus.initial,
    this.bookings,
    this.loadFailure,
    this.period = PropertyBookingsPeriod.upcoming,
  });

  /// The requested property, for retrying a failed load.
  final String propertyId;

  final RequestStatus loadStatus;

  /// The property and its bookings; kept while a refresh runs or after it
  /// fails.
  final PropertyBookingsEntity? bookings;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final PropertyBookingsPeriod period;

  /// The bookings of [period]; empty until loaded.
  List<PropertyBookingEntity> get visibleBookings {
    return bookings?.bookingsFor(period) ?? const <PropertyBookingEntity>[];
  }

  PropertyBookingsState copyWith({
    String? propertyId,
    RequestStatus? loadStatus,
    PropertyBookingsEntity? bookings,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    PropertyBookingsPeriod? period,
  }) {
    return PropertyBookingsState(
      propertyId: propertyId ?? this.propertyId,
      loadStatus: loadStatus ?? this.loadStatus,
      bookings: bookings ?? this.bookings,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      period: period ?? this.period,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    loadStatus,
    bookings,
    loadFailure,
    period,
  ];
}
