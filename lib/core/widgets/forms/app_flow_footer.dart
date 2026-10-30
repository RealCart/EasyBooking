import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/widgets/actions/app_secondary_button.dart';

class AppFlowFooter extends StatelessWidget {
  const AppFlowFooter({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.message,
    this.primaryLoading = false,
    this.showTopDivider = true,
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
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: showTopDivider
            ? const Border(top: BorderSide(color: AppColors.border))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (message case final String message) ...<Widget>[
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.compactBody.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget primaryButton = AppPrimaryButton.compact(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
                    isLoading: primaryLoading,
                  );
                  if (secondaryLabel == null) {
                    return primaryButton;
                  }

                  final Widget secondaryButton = AppSecondaryButton(
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed,
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
