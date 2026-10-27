import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: Text(title, style: AppTypography.sectionTitle),
      content: Text(message, style: AppTypography.body),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        0,
        AppSpacing.xLarge,
        AppSpacing.xLarge,
      ),
      actions: <Widget>[
        TextButton(onPressed: onCancel, child: Text(cancelLabel)),
        FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
      ],
    );
  }
}
