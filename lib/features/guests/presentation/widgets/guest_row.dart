import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_avatar.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';

/// One guest of «Гости и договоры»: initials, name, the latest stay, and
/// the contract status, or a chevron when nothing needs attention.
///
/// Draws the divider above itself; [showBottomDivider] closes the list.
final class GuestRow extends StatelessWidget {
  const GuestRow({
    required this.guest,
    required this.now,
    required this.onTap,
    this.showBottomDivider = false,
    super.key,
  });

  final GuestSummaryEntity guest;

  /// The moment relative copy («заезд сегодня») is measured from.
  final DateTime now;
  final VoidCallback onTap;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    const BorderSide divider = BorderSide(color: AppColors.border);

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: divider,
              bottom: showBottomDivider ? divider : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: <Widget>[
                GuestAvatar(initials: guest.initials),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        guest.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.action.copyWith(
                          height: 18 / 14,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        guest.details(now: now),
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
                _Trailing(guest: guest),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _Trailing extends StatelessWidget {
  const _Trailing({required this.guest});

  final GuestSummaryEntity guest;

  @override
  Widget build(BuildContext context) {
    if (guest.isSettled) {
      return SvgPicture.asset(
        AppAssets.icons.chevronRight,
        width: AppSizes.iconInline,
        height: AppSizes.iconInline,
        colorFilter: const ColorFilter.mode(AppColors.text, BlendMode.srcIn),
      );
    }
    final GuestContractStatus? status = guest.latestContractStatus;
    return Text(
      status?.label ?? 'Нет договора',
      maxLines: 1,
      style: AppTypography.caption.copyWith(
        height: 16 / 12,
        color: status?.color ?? AppColors.secondaryText,
      ),
    );
  }
}
