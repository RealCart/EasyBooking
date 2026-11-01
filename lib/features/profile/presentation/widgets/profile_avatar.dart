import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// Initials in a circle: 44 px in lists, 48 px for support, 72 px on
/// «Редактировать профиль».
final class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.initials,
    this.size = 44,
    this.backgroundColor = AppColors.surface,
    this.foregroundColor = AppColors.text,
    super.key,
  });

  final String initials;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = switch (size) {
      >= 64 => AppTypography.largeTitle,
      >= 48 => AppTypography.sectionTitle.copyWith(height: 22 / 18),
      _ => AppTypography.body.copyWith(
        fontWeight: FontWeight.w600,
        height: 18 / 14,
      ),
    };

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textScaler: TextScaler.noScaling,
          style: style.copyWith(color: foregroundColor),
        ),
      ),
    );
  }
}
