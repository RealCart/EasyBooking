import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppTextButtonStyle { accent, underlined, muted }

class AppTextButton extends StatelessWidget {
  const AppTextButton.accent({
    required this.label,
    this.onPressed,
    this.labelColor,
    super.key,
  }) : textButtonStyle = .accent;

  const AppTextButton.underlined({
    required this.label,
    this.onPressed,
    this.labelColor,
    super.key,
  }) : textButtonStyle = .underlined;

  const AppTextButton.muted({
    required this.label,
    this.onPressed,
    this.labelColor,
    super.key,
  }) : textButtonStyle = .muted;

  final String label;
  final Color? labelColor;
  final VoidCallback? onPressed;
  final AppTextButtonStyle textButtonStyle;

  bool get _isUnderlined => textButtonStyle == .underlined;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        labelColor ??
        switch (textButtonStyle) {
          .accent => AppColors.accent,
          .underlined => AppColors.text,
          .muted => AppColors.secondaryText,
        };

    final TextStyle textStyle = AppTypography.textAccent.copyWith(
      color: textColor,
      fontWeight: _isUnderlined ? .w600 : null,
      height: _isUnderlined ? 1.0 : null,
    );

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: textStyle,
    );

    final child = switch (textButtonStyle) {
      .underlined => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.text,
            ),
          ),
        ),
        child: text,
      ),
      _ => text,
    };

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
