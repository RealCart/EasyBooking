import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A list row of the settings screens: an optional [leading] slot, a title
/// with a subtitle, and a [trailing] slot, above a divider.
final class ProfileListRow extends StatelessWidget {
  const ProfileListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.pageGutter,
      vertical: 14,
    ),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Such as [ProfileChevron] or a role label.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final Widget? leading = this.leading;
    final Widget? trailing = this.trailing;
    final VoidCallback? onTap = this.onTap;

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              border: showDivider
                  ? const Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null)
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
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The square grey tile in front of a security row: a symbol or an icon.
final class ProfileRowTile extends StatelessWidget {
  const ProfileRowTile({required this.child, this.size = 40, super.key});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
        ),
        child: DefaultTextStyle.merge(
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            height: 18 / 14,
            color: AppColors.text,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The muted chevron at the end of a tappable row.
final class ProfileChevron extends StatelessWidget {
  const ProfileChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.icons.chevronRight,
      width: AppSizes.iconInline,
      height: AppSizes.iconInline,
      colorFilter: const ColorFilter.mode(
        AppColors.secondaryText,
        BlendMode.srcIn,
      ),
    );
  }
}

/// A short semibold trailing label, such as a role or «Этот».
final class ProfileTrailingLabel extends StatelessWidget {
  const ProfileTrailingLabel({
    required this.label,
    this.color = AppColors.text,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        color: color,
      ),
    );
  }
}
