import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppConfirmationDialog extends StatelessWidget {
  const AppConfirmationDialog({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.message,
    required this.title,
    this.onCancel,
    this.onConfirm,
    super.key,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.all(AppSpacing.xLarge),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  message,
                  style: AppTypography.compactBody.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 20,
                    children: <Widget>[
                      _DialogAction(
                        label: cancelLabel,
                        onPressed: onCancel,
                        color: AppColors.black,
                      ),
                      _DialogAction(
                        label: confirmLabel,
                        onPressed: onConfirm,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        textStyle: AppTypography.action,
      ),
      child: Text(label),
    );
  }
}
