part of 'guests_bloc.dart';

final class GuestsState extends Equatable {
  const GuestsState({
    this.query = '',
    this.loadStatus = RequestStatus.initial,
    this.directory,
    this.loadFailure,
  });

  /// The trimmed query of the newest load.
  final String query;

  final RequestStatus loadStatus;

  /// The last successful result; kept while a newer load runs or after it
  /// fails. Its `query` may differ from [query] until that load finishes.
  final GuestDirectoryEntity? directory;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  bool get hasLoaded => directory != null;

  /// Whether the user is searching, so the list title is not «Недавние
  /// гости».
  bool get isSearching => query.isNotEmpty;

  List<GuestSummaryEntity> get guests {
    return directory?.guests ?? const <GuestSummaryEntity>[];
  }

  List<GuestContractEntity> get contracts {
    return directory?.contracts ?? const <GuestContractEntity>[];
  }

  GuestsState copyWith({
    String? query,
    RequestStatus? loadStatus,
    GuestDirectoryEntity? directory,
    Failure? loadFailure,
    bool resetLoadFailure = false,
  }) {
    return GuestsState(
      query: query ?? this.query,
      loadStatus: loadStatus ?? this.loadStatus,
      directory: directory ?? this.directory,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    query,
    loadStatus,
    directory,
    loadFailure,
  ];
}
