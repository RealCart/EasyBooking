part of 'guests_bloc.dart';

sealed class GuestsEvent extends Equatable {
  const GuestsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the directory for the current query: added when the BLoC is
/// created, on retry, on pull-to-refresh, and after returning from a guest.
final class GuestsRequested extends GuestsEvent {
  const GuestsRequested();
}

/// The search text changed. Debounced; an empty query shows the recent
/// guests again.
final class GuestsQueryChanged extends GuestsEvent {
  const GuestsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}
