import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
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
    final Widget messageContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox.square(
          dimension: AppSizes.touchTarget,
          child: Center(
            child:
                icon ??
                Icon(
                  tone.icon,
                  color: tone.foregroundColor,
                  size: AppSizes.iconAction,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: AppTypography.action),
              const SizedBox(height: AppSpacing.xSmall),
              Text(message, style: AppTypography.body),
            ],
          ),
        ),
      ],
    );

    final Widget? action = actionLabel == null
        ? null
        : TextButton(onPressed: onAction, child: Text(actionLabel!));

    return Semantics(
      container: true,
      label: '$title. $message',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone.backgroundColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadii.media),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (action != null && constraints.maxWidth < 320) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    messageContent,
                    const SizedBox(height: AppSpacing.small),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: messageContent),
                  if (action != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.small),
                    action,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
