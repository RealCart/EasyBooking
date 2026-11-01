part of 'home_bloc.dart';

final class HomeState extends Equatable {
  const HomeState({
    this.loadStatus = RequestStatus.initial,
    this.overview,
    this.loadFailure,
    this.scope = HomeStayScope.arrivals,
  });

  final RequestStatus loadStatus;

  /// The last loaded overview; kept while a refresh runs or after it fails.
  final HomeOverviewEntity? overview;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final HomeStayScope scope;

  /// The stays of the selected [scope]; empty until the overview loads.
  List<HomeStayEntity> get stays {
    return overview?.staysFor(scope) ?? const <HomeStayEntity>[];
  }

  HomeState copyWith({
    RequestStatus? loadStatus,
    HomeOverviewEntity? overview,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    HomeStayScope? scope,
  }) {
    return HomeState(
      loadStatus: loadStatus ?? this.loadStatus,
      overview: overview ?? this.overview,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      scope: scope ?? this.scope,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    overview,
    loadFailure,
    scope,
  ];
}
