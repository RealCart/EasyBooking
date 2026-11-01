import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';

/// Served by a mock source until the guests API exists.
abstract interface class GuestsRepository {
  /// Guests and contracts matching [query]; an empty query returns the
  /// recent guests and every contract. The source does the matching, as a
  /// server search would.
  Future<Either<Failure, GuestDirectoryEntity>> getDirectory(String query);

  /// The guest [id]; an unknown id is a failure.
  Future<Either<Failure, GuestEntity>> getGuest(String id);

  /// Starts a contract draft for [guestId] and returns the draft's contract
  /// id. Asking again returns the same draft.
  Future<Either<Failure, String>> createContract(String guestId);
}
