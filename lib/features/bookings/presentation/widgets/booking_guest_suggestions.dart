import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_guest_booking_summary.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/presentation/widgets/booking_labels.dart';

/// Results of «Найти существующего гостя»: earlier guests to pick from.
/// Renders nothing while no query is searched.
final class BookingGuestSuggestions extends StatelessWidget {
  const BookingGuestSuggestions({
    required this.status,
    required this.guests,
    required this.onSelected,
    this.failureMessage,
    super.key,
  });

  final RequestStatus status;
  final List<BookingGuestEntity> guests;

  /// Shown when [status] is [RequestStatus.failure].
  final String? failureMessage;
  final ValueChanged<BookingGuestEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      RequestStatus.initial => const SizedBox.shrink(),
      RequestStatus.loading => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.small,
        children: <Widget>[
          AppSkeleton(height: 20, width: 200),
          AppSkeleton(height: 16, width: 140),
        ],
      ),
      RequestStatus.failure => _Message(
        text: failureMessage ?? 'Не удалось найти гостей',
        color: AppColors.error,
      ),
      RequestStatus.success when guests.isEmpty => const _Message(
        text: 'Гость не найден. Заполните данные ниже',
        color: AppColors.secondaryText,
      ),
      RequestStatus.success => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < guests.length; index++)
            Semantics(
              button: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
                child: AppGuestBookingSummary(
                  guestName: guests[index].fullName,
                  initials: guests[index].initials,
                  stayDetails: PhoneNumber.format(guests[index].phone),
                  onTap: () => onSelected(guests[index]),
                ),
              ),
            ),
        ],
      ),
    };
  }
}

final class _Message extends StatelessWidget {
  const _Message({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.compactBody.copyWith(color: color),
    );
  }
}
