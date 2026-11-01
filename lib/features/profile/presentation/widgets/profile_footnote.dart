import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';

/// A note under a top divider, with an optional leading icon and an
/// underlined action such as «Связаться».
final class ProfileFootnote extends StatelessWidget {
  const ProfileFootnote({
    required this.text,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.isEmphasized = false,
    super.key,
  });

  final String text;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shows [text] as primary text instead of a muted caption.
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final Widget? icon = this.icon;
    final String? actionLabel = this.actionLabel;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[icon, const SizedBox(width: 10)],
            Expanded(
              child: Text(
                text,
                style: isEmphasized
                    ? AppTypography.compactBody.copyWith(
                        height: 16 / 13,
                        color: AppColors.text,
                      )
                    : AppTypography.caption.copyWith(
                        height: 18 / 12,
                        color: AppColors.secondaryText,
                      ),
              ),
            ),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(width: 10),
              AppTextButton.underlined(label: actionLabel, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
