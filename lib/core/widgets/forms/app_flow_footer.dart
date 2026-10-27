import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/actions/app_button.dart';

class AppFlowFooter extends StatelessWidget {
  const AppFlowFooter({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.message,
    this.primaryLoading = false,
    super.key,
  }) : assert(
         (secondaryLabel == null && onSecondaryPressed == null) ||
             (secondaryLabel != null && onSecondaryPressed != null),
       );

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String? message;
  final bool primaryLoading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (message case final String message) ...<Widget>[
                Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget primaryButton = AppButton(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
                    isLoading: primaryLoading,
                    isExpanded: true,
                  );
                  if (secondaryLabel == null) {
                    return primaryButton;
                  }

                  final Widget secondaryButton = AppButton(
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed,
                    variant: AppButtonVariant.secondary,
                    isExpanded: true,
                  );
                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        primaryButton,
                        const SizedBox(height: 8),
                        secondaryButton,
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(child: secondaryButton),
                      const SizedBox(width: 12),
                      Expanded(child: primaryButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
