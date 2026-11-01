import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_accent_block.dart';
import 'package:easy_booking/features/profile/presentation/widgets/team_labels.dart';

/// A role of «Роли»: its color bar, name, and what it can access.
final class TeamRoleRow extends StatelessWidget {
  const TeamRoleRow({required this.role, super.key});

  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pageGutter,
        vertical: 13,
      ),
      child: ProfileAccentBlock(
        color: role.accentColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: <Widget>[
              Text(
                role.teamLabel,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 18 / 14,
                  color: AppColors.text,
                ),
              ),
              Text(
                role.description,
                style: AppTypography.caption.copyWith(
                  height: 18 / 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
