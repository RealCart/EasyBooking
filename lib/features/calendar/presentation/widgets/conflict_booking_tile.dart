import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// One of the overlapping bookings on «Конфликт календарей»: a coloured
/// stripe, the source and guest, the status on the right, the dates, and
/// the price line. Tapping it opens the booking.
final class ConflictBookingTile extends StatelessWidget {
  const ConflictBookingTile({
    required this.title,
    required this.statusLabel,
    required this.dates,
    required this.details,
    required this.color,
    required this.onTap,
    this.showBottomDivider = false,
    super.key,
  });

  final String title;
  final String statusLabel;
  final String dates;
  final String details;

  /// The stripe and the status text.
  final Color color;
  final VoidCallback onTap;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.border),
              bottom: showBottomDivider
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.body.copyWith(
                                  height: 18 / 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              statusLabel,
                              style: AppTypography.caption.copyWith(
                                height: 16 / 12,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dates,
                          style: AppTypography.compactBody.copyWith(
                            height: 16 / 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          details,
                          style: AppTypography.compactBody.copyWith(
                            height: 16 / 13,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
