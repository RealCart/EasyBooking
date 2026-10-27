import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppArrivalCard extends StatelessWidget {
  const AppArrivalCard({
    required this.time,
    required this.propertyName,
    required this.stayDetails,
    super.key,
    this.status,
    this.leading,
    this.action,
    this.onTap,
  });

  final String time;
  final String propertyName;
  final String stayDetails;
  final String? status;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(16);

    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                SizedBox.square(dimension: 44, child: Center(child: leading)),
                const SizedBox(width: 12),
              ] else ...<Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 48),
                  child: Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.action.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (leading != null) ...<Widget>[
                      Text(
                        time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      propertyName,
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
                    if (status != null) ...<Widget>[
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            status!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
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
}
