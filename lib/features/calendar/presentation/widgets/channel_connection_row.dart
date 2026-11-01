import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// One property linked to a channel, on «Канал»: its name, sync mode, and
/// whether the import works. Tapping it shows that property's calendar.
final class ChannelConnectionRow extends StatelessWidget {
  const ChannelConnectionRow({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.isFailed,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final bool isFailed;

  /// Its calendar is the one shown above the list.
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          height: 18 / 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          decoration: isSelected
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                      Text(
                        subtitle,
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
                  statusLabel,
                  style: AppTypography.caption.copyWith(
                    height: 16 / 12,
                    color: isFailed ? AppColors.warning : AppColors.success,
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
