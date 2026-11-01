import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';

/// One stay on «Гость»: a status bar, the property and dates, and «Сейчас»
/// / «Скоро» for a stay that is not over, otherwise a chevron.
final class GuestStayRow extends StatelessWidget {
  const GuestStayRow({required this.stay, required this.onTap, super.key});

  static const double _barWidth = 4;
  static const double _barHeight = 44;
  static const double _barRadius = 2;

  final GuestStayEntity stay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color barColor = switch (stay.status) {
      GuestStayStatus.current => AppColors.accent,
      GuestStayStatus.upcoming => AppColors.info,
      GuestStayStatus.past => AppColors.border,
    };

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
                width: _barWidth,
                height: _barHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(_barRadius),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      stay.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.action.copyWith(
                        height: 18 / 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stay.details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        height: 16 / 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              switch (stay.status) {
                GuestStayStatus.current => const _StayBadge(
                  label: 'Сейчас',
                  background: AppColors.successSurface,
                  foreground: AppColors.success,
                ),
                GuestStayStatus.upcoming => const _StayBadge(
                  label: 'Скоро',
                  background: AppColors.infoSurface,
                  foreground: AppColors.info,
                ),
                GuestStayStatus.past => SvgPicture.asset(
                  AppAssets.icons.chevronRight,
                  width: AppSizes.iconInline,
                  height: AppSizes.iconInline,
                  colorFilter: const ColorFilter.mode(
                    AppColors.secondaryText,
                    BlendMode.srcIn,
                  ),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

final class _StayBadge extends StatelessWidget {
  const _StayBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  static const double _radius = 5;

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(_radius)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: 5,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: AppTypography.caption.copyWith(
            height: 16 / 12,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
