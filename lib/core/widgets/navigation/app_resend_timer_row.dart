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
    return Semantics(
      label: prompt,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.touchTarget),
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.text,
                    overlayColor: Colors.transparent,
                    disabledForegroundColor: AppColors.text,
                    textStyle: AppTypography.action,
                  ),
                  onPressed: isWaiting ? null : onResend,
                  child: Text(actionLabel),
                ),
              ),
            ),
            if (isWaiting) ...<Widget>[
              const SizedBox(width: AppSpacing.medium),
              Text(
                _formatDuration(remaining),
                style: AppTypography.compactBody.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    final int minutes = totalSeconds ~/ Duration.secondsPerMinute;
    final int seconds = totalSeconds % Duration.secondsPerMinute;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
