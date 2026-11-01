import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';

/// «Заезд» / «Выезд»: shows a date and time as `28 окт, 14:00` in a box
/// like the picker fields, and asks the owner to pick a new one on tap.
final class BookingDateTimeField extends StatelessWidget {
  const BookingDateTimeField({
    required this.label,
    required this.value,
    required this.onPressed,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  static const double _minHeight = 72;

  final String label;
  final DateTime value;

  /// Opens the date and time pickers.
  final VoidCallback onPressed;

  /// A server field error shown under the box.
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String? errorText = this.errorText;
    final bool hasError = errorText != null;
    final String valueLabel =
        '${DateFormatter.dayMonth(value, short: true)}, '
        '${DateFormatter.time(value)}';
    final VoidCallback? onTap = enabled ? onPressed : null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: <String>[label, valueLabel, ?errorText].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Container(
                constraints: const BoxConstraints(minHeight: _minHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: hasError ? AppColors.error : AppColors.border,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.field),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: hasError
                            ? AppColors.error
                            : AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (errorText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              errorText,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
