part of 'guest_detail_bloc.dart';

sealed class GuestDetailEvent extends Equatable {
  const GuestDetailEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [guestId]: added when the BLoC is created and on retry.
final class GuestDetailRequested extends GuestDetailEvent {
  const GuestDetailRequested(this.guestId);

  final String guestId;

  @override
  List<Object?> get props => <Object?>[guestId];
}

/// «Создать договор»: starts a contract draft for the loaded guest.
/// Ignored before the guest has loaded and while a draft is being created.
final class GuestContractCreationRequested extends GuestDetailEvent {
  const GuestContractCreationRequested();
}
