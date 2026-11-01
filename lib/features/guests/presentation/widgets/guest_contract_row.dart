import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';

/// One contract: a document badge, `№ EB-1048`, [details], and the status.
final class GuestContractRow extends StatelessWidget {
  const GuestContractRow({
    required this.contract,
    required this.details,
    required this.onTap,
    super.key,
  });

  static const double _badgeSize = 40;
  static const double _badgeRadius = 7;

  final GuestContractEntity contract;

  /// `Подписан 18 октября` on «Гость», the guest and property on the
  /// «Договоры» tab.
  final String details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.pageGutter,
            vertical: AppSpacing.medium,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: _badgeSize,
                height: _badgeSize,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.all(
                    Radius.circular(_badgeRadius),
                  ),
                ),
                child: SvgPicture.asset(
                  AppAssets.icons.fileText,
                  width: 19,
                  height: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      contract.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.action.copyWith(
                        height: 18 / 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        height: 16 / 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                contract.status.label,
                maxLines: 1,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 16 / 12,
                  color: contract.status.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
