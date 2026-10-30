import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : _minimumHeight = AppSizes.primaryButtonHeight;

  const AppPrimaryButton.compact({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : _minimumHeight = 48;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double _minimumHeight;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || onPressed == null;

    final Widget button = FilledButton(
      onPressed: isDisabled ? null : onPressed,
      style: ButtonStyle(
        animationDuration: const Duration(milliseconds: 120),
        backgroundColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.border;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.accentPressed;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.accentHover;
          }
          return AppColors.accent;
        }),
        foregroundColor: const WidgetStatePropertyAll<Color>(
          AppColors.onAccent,
        ),
        minimumSize: WidgetStatePropertyAll<Size>(
          Size(0, _minimumHeight),
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.16);
          }
          return Colors.transparent;
        }),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
          EdgeInsets.symmetric(horizontal: AppSizes.pageGutter, vertical: 12),
        ),
        shape: const WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
          ),
        ),
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          AppTypography.action,
        ),
        elevation: const WidgetStatePropertyAll<double>(0),
      ),
      child: isLoading
          ? const RepaintBoundary(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onAccent,
                ),
              ),
            )
          : Text(label, textAlign: TextAlign.center),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => SizedBox(
        width: constraints.hasBoundedWidth ? double.infinity : null,
        child: button,
      ),
    );
  }
}
