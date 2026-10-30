import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Read-only field that opens a picker, styled like `AppTextField`.
final class AccountCityField extends StatelessWidget {
  const AccountCityField({
    required this.label,
    required this.hint,
    required this.onPressed,
    this.value,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  static const double _minHeight = 72;

  final String label;
  final String hint;
  final VoidCallback onPressed;
  final String? value;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String? value = this.value;
    final String? errorText = this.errorText;
    final bool hasError = errorText != null;
    final VoidCallback? onTap = enabled ? onPressed : null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: <String>[label, value ?? hint, ?errorText].join(', '),
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
                      value ?? hint,
                      style: AppTypography.bodyLarge.copyWith(
                        color: value == null
                            ? AppColors.secondaryText
                            : AppColors.text,
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
