import 'package:flutter/material.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/navigation/app_header_back_button.dart';

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: SizedBox(
        height: _height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
          child: Row(
            children: <Widget>[
              AppHeaderBackButton(
                semanticLabel: backSemanticLabel,
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.primaryText.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null)
                action
              else
                const SizedBox(width: AppSizes.touchTarget),
            ],
          ),
        ),
      ),
    );
  }
}
