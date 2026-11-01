import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_logo.dart';

/// How the trailing text of a [ChannelTile] looks.
enum ChannelTileTrailingTone { success, error, neutral, link }

/// One channel on «Каналы»: logo, name, a summary line, and its status or
/// an underlined action on the right. The whole row is tappable.
final class ChannelTile extends StatelessWidget {
  const ChannelTile({
    required this.initial,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingTone,
    required this.onTap,
    this.showBottomDivider = false,
    super.key,
  });

  final String initial;
  final String title;
  final String subtitle;
  final String trailing;
  final ChannelTileTrailingTone trailingTone;
  final VoidCallback onTap;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final bool isLink = trailingTone == ChannelTileTrailingTone.link;
    final Color trailingColor = switch (trailingTone) {
      ChannelTileTrailingTone.success => AppColors.success,
      ChannelTileTrailingTone.error => AppColors.error,
      ChannelTileTrailingTone.neutral => AppColors.secondaryText,
      ChannelTileTrailingTone.link => AppColors.text,
    };
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.border),
              bottom: showBottomDivider
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
            child: Row(
              children: <Widget>[
                ChannelLogo(initial: initial),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.rowTitle.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.compactBody.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Text(
                  trailing,
                  style: AppTypography.caption.copyWith(
                    height: 16 / 12,
                    color: trailingColor,
                    decoration: isLink ? TextDecoration.underline : null,
                    decorationColor: trailingColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
