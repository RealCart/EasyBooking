import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const AppDetailHeader({
    required this.title,
    required this.onBack,
    this.action,
    this.backSemanticLabel = 'Back',
    this.showDivider = true,
    super.key,
  });

  static const double _height = 56;

  final String title;
  final VoidCallback onBack;
  final Widget? action;
  final String backSemanticLabel;
  final bool showDivider;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final Widget? action = this.action;

    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: SizedBox(
          height: _height,
          child: Row(
            children: <Widget>[
              _BackButton(
                semanticLabel: backSemanticLabel,
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.primaryText.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(width: AppSpacing.small),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.touchTarget,
                    minHeight: AppSizes.touchTarget,
                  ),
                  child: Center(child: action),
                ),
                const SizedBox(width: AppSpacing.medium),
              ] else
                const SizedBox(width: AppSpacing.large),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.semanticLabel, required this.onPressed});

  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        constraints: const BoxConstraints.tightFor(
          width: AppSizes.touchTarget,
          height: AppSizes.touchTarget,
        ),
        padding: EdgeInsets.zero,
        tooltip: semanticLabel,
        onPressed: onPressed,
        icon: SvgPicture.asset(
          AppAssets.icons.chevronLeft,
          width: AppSizes.iconAppBar,
          height: AppSizes.iconAppBar,
          colorFilter: const ColorFilter.mode(
            AppColors.text,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
