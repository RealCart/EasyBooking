import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A read-only iCal link in a bordered box: «Импорт занятости» or
/// «Экспорт из EasyBooking». The link can be selected and copied.
final class ChannelLinkField extends StatelessWidget {
  const ChannelLinkField({required this.label, required this.url, super.key});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: 13,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.caption.copyWith(
                height: 16 / 12,
                color: AppColors.secondaryText,
              ),
            ),
            SelectableText(
              url,
              maxLines: 1,
              style: AppTypography.compactBody.copyWith(color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}
