import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/feedback/app_feedback_tone.dart';

final class AppCallout extends StatelessWidget {
  const AppCallout({
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.icon,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final AppFeedbackTone tone;
  final String? actionLabel;
  final Widget? icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.media)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox.square(
              dimension: 20,
              child: icon ?? SvgPicture.asset(tone.iconPath),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTypography.action.copyWith(
                      color: tone.foregroundColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.compactBody.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (actionLabel != null)
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        foregroundColor: tone.foregroundColor,
                        overlayColor: Colors.transparent,
                      ),
                      child: Text(actionLabel!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
