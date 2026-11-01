part of 'profile_bloc.dart';

final class ProfileState extends Equatable {
  const ProfileState({
    this.loadStatus = RequestStatus.initial,
    this.profile,
    this.loadFailure,
    this.signOutStatus = RequestStatus.initial,
    this.signOutFailure,
  });

  final RequestStatus loadStatus;
  final ProfileEntity? profile;
  final Failure? loadFailure;
  final RequestStatus signOutStatus;
  final Failure? signOutFailure;

  ProfileState copyWith({
    RequestStatus? loadStatus,
    ProfileEntity? profile,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? signOutStatus,
    Failure? signOutFailure,
    bool resetSignOutFailure = false,
  }) {
    return ProfileState(
      loadStatus: loadStatus ?? this.loadStatus,
      profile: profile ?? this.profile,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      signOutStatus: signOutStatus ?? this.signOutStatus,
      signOutFailure: resetSignOutFailure
          ? null
          : signOutFailure ?? this.signOutFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    profile,
    loadFailure,
    signOutStatus,
    signOutFailure,
  ];
}
