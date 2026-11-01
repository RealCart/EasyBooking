import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// The guest's initials in a circle: 44 px in lists, 64 px on «Гость».
final class GuestAvatar extends StatelessWidget {
  const GuestAvatar({required this.initials, super.key}) : _isLarge = false;

  const GuestAvatar.large({required this.initials, super.key})
    : _isLarge = true;

  static const double _size = 44;
  static const double _largeSize = 64;

  final String initials;
  final bool _isLarge;

  @override
  Widget build(BuildContext context) {
    final double size = _isLarge ? _largeSize : _size;
    final TextStyle style = _isLarge
        ? AppTypography.sectionTitle.copyWith(
            fontSize: 20,
            height: 24 / 20,
            color: AppColors.text,
          )
        : AppTypography.compactBody.copyWith(
            fontWeight: FontWeight.w600,
            height: 16 / 13,
            color: AppColors.text,
          );

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          maxLines: 1,
          overflow: TextOverflow.clip,
          textScaler: TextScaler.noScaling,
          style: style,
        ),
      ),
    );
  }
}
