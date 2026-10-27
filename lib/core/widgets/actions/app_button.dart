import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = false,
    this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final double height = variant == AppButtonVariant.text ? 44 : 52;
    final Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isLoading
          ? SizedBox.square(
              key: const ValueKey<String>('loading'),
              dimension: 20,
              child: Semantics(
                label: 'Loading',
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              key: const ValueKey<String>('content'),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading case final Widget leading) ...<Widget>[
                  leading,
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: _primaryStyle,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: _secondaryStyle,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: _textStyle,
        child: child,
      ),
    };

    return SizedBox(
      width: isExpanded ? double.infinity : null,
      height: height,
      child: button,
    );
  }

  static final ButtonStyle _primaryStyle = ButtonStyle(
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
    foregroundColor: WidgetStateProperty.resolveWith<Color>((
      Set<WidgetState> states,
    ) {
      return states.contains(WidgetState.disabled)
          ? AppColors.secondaryText
          : AppColors.onAccent;
    }),
    overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: 20),
    ),
    shape: WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textStyle: const WidgetStatePropertyAll<TextStyle>(AppTypography.action),
  );

  static final ButtonStyle _secondaryStyle = OutlinedButton.styleFrom(
    backgroundColor: AppColors.background,
    disabledBackgroundColor: AppColors.surface,
    foregroundColor: AppColors.text,
    disabledForegroundColor: AppColors.secondaryText,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: AppTypography.action,
  );

  static final ButtonStyle _textStyle = TextButton.styleFrom(
    foregroundColor: AppColors.accent,
    disabledForegroundColor: AppColors.secondaryText,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: AppTypography.action,
  );
}
