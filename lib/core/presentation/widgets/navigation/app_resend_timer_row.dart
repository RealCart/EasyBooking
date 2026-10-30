import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Resend action with a countdown. The action is blocked while [remaining]
/// is above zero.
///
/// With [leading] or [subtitle] the row uses the detailed layout of the SMS
/// screen: an icon slot, a 16 px title with a visible subtitle, and the
/// countdown in the text color. Otherwise it is the compact text action of
/// the design system.
final class AppResendTimerRow extends StatelessWidget {
  const AppResendTimerRow({
    required this.prompt,
    required this.actionLabel,
    required this.onResend,
    this.remaining,
    this.leading,
    this.subtitle,
    super.key,
  });

  static const double _leadingSlotWidth = 32;

  /// Announced to screen readers with the action.
  final String prompt;
  final String actionLabel;
  final VoidCallback onResend;
  final Duration? remaining;
  final Widget? leading;

  /// Visible secondary line under [actionLabel], for example
  /// «Можно через 00:28».
  final String? subtitle;

  /// Time left before resend is allowed, or `null` when it is allowed.
  Duration? get _waitingTime {
    final Duration? remaining = this.remaining;
    return remaining != null && remaining > Duration.zero ? remaining : null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget row = leading != null || subtitle != null
        ? _buildDetailed()
        : _buildCompact();
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: row,
    );
  }

  Widget _buildCompact() {
    final Duration? waitingTime = _waitingTime;
    final bool isWaiting = waitingTime != null;
    return Semantics(
      label: prompt,
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
          if (waitingTime != null) ...<Widget>[
            const SizedBox(width: AppSpacing.medium),
            Text(
              _formatDuration(waitingTime),
              style: AppTypography.compactBody.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailed() {
    final Duration? waitingTime = _waitingTime;
    final bool isWaiting = waitingTime != null;
    final Widget? leading = this.leading;
    final String? subtitle = this.subtitle;
    final VoidCallback? onTap = isWaiting ? null : onResend;

    return Semantics(
      button: true,
      enabled: !isWaiting,
      label: actionLabel,
      hint: prompt,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
          child: Row(
            spacing: AppSpacing.medium,
            children: <Widget>[
              if (leading != null)
                SizedBox(
                  width: _leadingSlotWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: leading,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xSmall,
                  children: <Widget>[
                    Text(
                      actionLabel,
                      style: AppTypography.primaryText.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppTypography.compactBody.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (waitingTime != null)
                Text(
                  _formatDuration(waitingTime),
                  textAlign: TextAlign.right,
                  style: AppTypography.compactBody.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
            ],
          ),
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
