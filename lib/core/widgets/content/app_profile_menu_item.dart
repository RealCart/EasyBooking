import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppProfileMenuItem extends StatelessWidget {
  const AppProfileMenuItem({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                SizedBox.square(dimension: 44, child: Center(child: leading)),
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
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.compactBody.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Center(
                  child:
                      trailing ??
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondaryText,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
