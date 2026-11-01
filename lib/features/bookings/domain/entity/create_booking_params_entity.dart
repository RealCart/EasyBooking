import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';

/// Input of `CreateBookingUsecase`: the «Цена и источник» form.
final class CreateBookingParamsEntity extends Equatable {
  const CreateBookingParamsEntity({
    required this.draftId,
    required this.totalPrice,
    required this.deposit,
    required this.source,
    required this.createContract,
    this.comment,
  });

  /// `BookingDraftEntity.id` of the draft saved on step 1.
  final String draftId;

  /// Whole tenge; more than zero.
  final int totalPrice;

  /// Whole tenge; zero or more.
  final int deposit;

  /// One of [BookingSource.manual].
  final BookingSource source;

  /// «Комментарий для команды»; blank means none.
  final String? comment;

  /// «Создать договор после брони».
  final bool createContract;

  @override
  List<Object?> get props => <Object?>[
    draftId,
    totalPrice,
    deposit,
    source,
    comment,
    createContract,
  ];
}
