import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';

/// The «Гости» and «Договоры» tabs for one search query.
final class GuestDirectoryEntity extends Equatable {
  const GuestDirectoryEntity({
    required this.query,
    required this.guests,
    required this.contracts,
    required this.totalGuestCount,
    required this.receivedAt,
  });

  /// The trimmed query this result answers; empty for the default view.
  final String query;

  /// For an empty [query], the recently active guests («Недавние гости»);
  /// otherwise every matching guest. Most recent activity first.
  final List<GuestSummaryEntity> guests;

  /// The contracts matching [query]: awaiting a signature first, then the
  /// newest.
  final List<GuestContractEntity> contracts;

  /// How many guests the user has in all («12 гостей»), regardless of
  /// [query].
  final int totalGuestCount;

  /// When the result was produced. Relative copy («заезд сегодня») is
  /// measured from it.
  final DateTime receivedAt;

  @override
  List<Object?> get props => <Object?>[
    query,
    guests,
    contracts,
    totalGuestCount,
    receivedAt,
  ];
}
