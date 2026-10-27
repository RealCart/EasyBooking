import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppPropertyRow extends StatelessWidget {
  const AppPropertyRow({
    required this.title,
    required this.subtitle,
    super.key,
    this.price,
    this.unitLabel,
    this.status,
    this.image,
    this.action,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final String? price;
  final String? unitLabel;
  final String? status;
  final Widget? image;
  final Widget? action;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: <Widget>[
              if (image != null) ...<Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(dimension: 56, child: image),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.primaryText.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (status != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        status!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (price != null) ...<Widget>[
                const SizedBox(width: 12),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: price,
                          style: AppTypography.action.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                        if (unitLabel != null)
                          TextSpan(
                            text: '\n${unitLabel!}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
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
}
