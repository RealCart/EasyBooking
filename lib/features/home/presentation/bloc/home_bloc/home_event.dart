part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the overview: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class HomeOverviewRequested extends HomeEvent {
  const HomeOverviewRequested();
}

/// The user picked the stays to show.
final class HomeScopeSelected extends HomeEvent {
  const HomeScopeSelected(this.scope);

  final HomeStayScope scope;

  @override
  List<Object?> get props => <Object?>[scope];
}
