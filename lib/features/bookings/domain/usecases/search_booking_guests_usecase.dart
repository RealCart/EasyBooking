import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/search_booking_guests_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

/// Finds guests of earlier bookings, to fill the guest of a new one. A blank
/// query finds nothing and sends no request.
final class SearchBookingGuestsUsecase
    implements
        Usecase<
          Future<Either<Failure, List<BookingGuestEntity>>>,
          SearchBookingGuestsParamsEntity
        > {
  const SearchBookingGuestsUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, List<BookingGuestEntity>>> call(
    SearchBookingGuestsParamsEntity params,
  ) async {
    final String query = params.query.trim();
    if (query.isEmpty) {
      return const Right<Failure, List<BookingGuestEntity>>(
        <BookingGuestEntity>[],
      );
    }
    return _repository.searchGuests(query);
  }
}
