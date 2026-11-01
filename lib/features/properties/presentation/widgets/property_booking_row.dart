import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// One booking on the property's «Брони» tab: the check-in day, a bar in
/// the channel colour, the guest, the status, and two detail lines.
final class PropertyBookingRow extends StatelessWidget {
  const PropertyBookingRow({
    required this.dayLabel,
    required this.day,
    required this.accentColor,
    required this.guestName,
    required this.statusLabel,
    required this.statusColor,
    required this.details,
    required this.footnote,
    required this.onTap,
    this.isFootnoteWarning = false,
    this.showDivider = true,
    super.key,
  });

  /// `СЕГ` for today, otherwise the short weekday, such as `ВС`.
  final String dayLabel;

  /// `22`
  final String day;
  final Color accentColor;
  final String guestName;
  final String statusLabel;
  final Color statusColor;

  /// `22–25 октября · Airbnb`
  final String details;

  /// `3 ночи · 127 500 ₸` or `Договор не создан`.
  final String footnote;
  final bool isFootnoteWarning;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageGutter,
              vertical: 14,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    child: Column(
                      children: <Widget>[
                        Text(
                          dayLabel,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondaryText,
                            height: 16 / 12,
                          ),
                        ),
                        Text(
                          day,
                          textAlign: TextAlign.center,
                          style: AppTypography.largeTitle.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: 3),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xSmall,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                guestName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.rowTitle.copyWith(
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              statusLabel,
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                height: 16 / 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          details,
                          style: AppTypography.compactBody.copyWith(
                            color: AppColors.secondaryText,
                            height: 16 / 13,
                          ),
                        ),
                        Text(
                          footnote,
                          style: AppTypography.caption.copyWith(
                            color: isFootnoteWarning
                                ? AppColors.warning
                                : AppColors.secondaryText,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Center(
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        AppAssets.icons.chevronRight,
                        width: AppSizes.iconInline,
                        height: AppSizes.iconInline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
