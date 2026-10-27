import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppGuestBookingSummary extends StatelessWidget {
  const AppGuestBookingSummary({
    required this.guestName,
    required this.stayDetails,
    super.key,
    this.initials,
    this.avatar,
    this.trailingText,
    this.action,
    this.onTap,
    this.showDivider = true,
  });

  final String guestName;
  final String stayDetails;
  final String? initials;
  final Widget? avatar;
  final String? trailingText;
  final Widget? action;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Widget fallbackAvatar = DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials ?? _initialsFrom(guestName),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTypography.action.copyWith(color: AppColors.text),
        ),
      ),
    );

    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: <Widget>[
              ClipOval(
                child: SizedBox.square(
                  dimension: 48,
                  child: avatar ?? fallbackAvatar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      guestName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.primaryText.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stayDetails,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null) ...<Widget>[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    trailingText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(child: action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initialsFrom(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
