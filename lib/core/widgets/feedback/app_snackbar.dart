import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppSnackbar extends StatelessWidget {
  const AppSnackbar({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  SnackBar toSnackBar({Duration duration = const Duration(seconds: 4)}) {
    return SnackBar(
      content: this,
      duration: duration,
      backgroundColor: AppColors.text,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                style: AppTypography.body.copyWith(color: AppColors.background),
              ),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(width: AppSpacing.small),
              Flexible(
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.background,
                    overlayColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    textStyle: AppTypography.compactBody.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
