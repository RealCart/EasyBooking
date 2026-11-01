import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// An uppercase group caption such as «ОПЕРАЦИИ».
final class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel({
    required this.label,
    this.isFirst = false,
    super.key,
  });

  final String label;

  /// The first group sits closer to the header.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.pageGutter,
          isFirst ? 18 : 22,
          AppSizes.pageGutter,
          8,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.compactBody.copyWith(
            fontWeight: FontWeight.w600,
            height: 16 / 13,
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}

/// A section title such as «Личные данные», 18 px semibold.
final class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: AppTypography.sectionTitle.copyWith(
          height: 22 / 18,
          color: AppColors.text,
        ),
      ),
    );
  }
}
