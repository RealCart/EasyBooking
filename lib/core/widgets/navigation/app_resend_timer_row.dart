import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppResendTimerRow extends StatelessWidget {
  const AppResendTimerRow({
    required this.prompt,
    required this.actionLabel,
    required this.onResend,
    this.remaining,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onResend;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final Duration? remaining = this.remaining;
    final bool isWaiting = remaining != null && remaining > Duration.zero;
    final String label = isWaiting
        ? '$actionLabel ${_formatDuration(remaining)}'
        : actionLabel;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            prompt,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSizes.touchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
            ),
            foregroundColor: AppColors.text,
            disabledForegroundColor: AppColors.secondaryText,
            textStyle: AppTypography.action,
          ),
          onPressed: isWaiting ? null : onResend,
          child: Text(label),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ Duration.secondsPerMinute;
    final int seconds = totalSeconds % Duration.secondsPerMinute;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
