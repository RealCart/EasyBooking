part of 'help_bloc.dart';

sealed class HelpEvent extends Equatable {
  const HelpEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the help center: added when the BLoC is created and on retry.
final class HelpRequested extends HelpEvent {
  const HelpRequested();
}
