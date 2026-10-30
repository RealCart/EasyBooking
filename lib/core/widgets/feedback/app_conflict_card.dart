import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppConflictCard extends StatelessWidget {
  const AppConflictCard({
    required this.message,
    required this.primaryActionLabel,
    required this.title,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    super.key,
  });

  final String title;
  final String message;
  final String primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.errorSurface,
        border: Border(left: BorderSide(color: AppColors.error, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTypography.action.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              message,
              style: AppTypography.compactBody.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.large,
              children: <Widget>[
                if (secondaryActionLabel != null)
                  _ConflictAction(
                    label: secondaryActionLabel!,
                    onPressed: onSecondaryAction,
                    color: AppColors.black,
                    underlined: true,
                  ),
                _ConflictAction(
                  label: primaryActionLabel,
                  onPressed: onPrimaryAction,
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _ConflictAction extends StatelessWidget {
  const _ConflictAction({
    required this.label,
    required this.onPressed,
    required this.color,
    this.underlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool underlined;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        textStyle: AppTypography.compactBody.copyWith(
          fontWeight: FontWeight.w600,
          decoration: underlined
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
      child: Text(label),
    );
  }
}
