import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_secondary_button.dart';

/// The bottom bar of «Канал» and «Конфликт календарей»: a hint and two
/// actions, an outlined one sized to its label and a filled one taking the
/// rest of the row. Either action can show progress.
final class CalendarDecisionFooter extends StatelessWidget {
  const CalendarDecisionFooter({
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.message,
    this.isSecondaryLoading = false,
    this.isPrimaryLoading = false,
    super.key,
  });

  /// Only the filled action, for example «Готово».
  const CalendarDecisionFooter.single({
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.message,
    this.isPrimaryLoading = false,
    super.key,
  }) : secondaryLabel = null,
       onSecondaryPressed = null,
       isSecondaryLoading = false;

  /// Below this width the actions are stacked, primary first.
  static const double _stackBelowWidth = 340;

  final String? message;

  /// Hides the outlined action when `null`.
  final String? secondaryLabel;

  /// Disables the outlined action when `null`.
  final VoidCallback? onSecondaryPressed;
  final bool isSecondaryLoading;
  final String primaryLabel;

  /// Disables the filled action when `null`.
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final String? message = this.message;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.medium),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pageGutter,
            14,
            AppSizes.pageGutter,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (message != null) ...<Widget>[
                Text(
                  message,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Widget primary = AppPrimaryButton.compact(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
                    isLoading: isPrimaryLoading,
                  );
                  final String? secondaryLabel = this.secondaryLabel;
                  if (secondaryLabel == null) {
                    return primary;
                  }
                  final Widget secondary = isSecondaryLoading
                      ? _OutlinedProgress(label: secondaryLabel)
                      : AppSecondaryButton(
                          label: secondaryLabel,
                          onPressed: onSecondaryPressed,
                        );
                  if (constraints.maxWidth < _stackBelowWidth) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        primary,
                        const SizedBox(height: AppSpacing.small),
                        secondary,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      // Unbounded, so the outlined action hugs its label.
                      secondary,
                      const SizedBox(width: 10),
                      Expanded(child: primary),
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

/// The outlined action while its request runs. The hidden label keeps the
/// button as wide as before, so the row does not jump.
final class _OutlinedProgress extends StatelessWidget {
  const _OutlinedProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: false,
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: AppSecondaryButton(label: label, onPressed: null),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.text),
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRadii.field),
                ),
              ),
            ),
          ),
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
