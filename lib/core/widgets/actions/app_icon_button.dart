import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.foregroundColor = AppColors.text,
    this.backgroundColor = Colors.transparent,
    super.key,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: semanticLabel,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledForegroundColor: AppColors.border,
          foregroundColor: foregroundColor,
          minimumSize: const Size.square(44),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
