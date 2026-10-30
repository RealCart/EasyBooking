import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.isSelected = false,
    super.key,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: AppSizes.touchTarget,
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1,
          child: IconButton(
            onPressed: onPressed,
            isSelected: isSelected,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: AppSizes.touchTarget,
              height: AppSizes.touchTarget,
            ),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(
                isSelected ? AppColors.text : AppColors.white,
              ),
              foregroundColor: WidgetStatePropertyAll<Color>(
                isSelected ? AppColors.onAccent : AppColors.text,
              ),
              overlayColor: const WidgetStatePropertyAll<Color>(
                Colors.transparent,
              ),
              shape: const WidgetStatePropertyAll<OutlinedBorder>(
                CircleBorder(),
              ),
            ),
            icon: IconTheme(
              data: IconThemeData(
                color: isSelected ? AppColors.onAccent : AppColors.text,
                size: AppSizes.iconAction,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class AppBackIconButton extends StatelessWidget {
  const AppBackIconButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: 'Back',
      onPressed: onPressed,
      icon: _AppPaperIcon(path: AppAssets.icons.chevronLeft),
    );
  }
}

class AppMoreIconButton extends StatelessWidget {
  const AppMoreIconButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: 'More options',
      onPressed: onPressed,
      icon: _AppPaperIcon(path: AppAssets.icons.moreVertical),
    );
  }
}

class AppSavedIconButton extends StatelessWidget {
  const AppSavedIconButton({
    required this.isSaved,
    required this.onPressed,
    super.key,
  });

  final bool isSaved;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: isSaved ? 'Remove from saved' : 'Save',
      onPressed: onPressed,
      isSelected: isSaved,
      icon: _AppPaperIcon(
        path: isSaved ? AppAssets.icons.heartFilled : AppAssets.icons.heart,
        color: isSaved ? AppColors.onAccent : AppColors.text,
      ),
    );
  }
}

class AppChevronIconButton extends StatelessWidget {
  const AppChevronIconButton({
    required this.onPressed,
    this.direction = AppChevronDirection.right,
    super.key,
  });

  final VoidCallback? onPressed;
  final AppChevronDirection direction;

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      semanticLabel: direction == AppChevronDirection.right
          ? 'Open'
          : 'Go back',
      onPressed: onPressed,
      icon: _AppPaperIcon(
        path: direction == AppChevronDirection.right
            ? AppAssets.icons.chevronRight
            : AppAssets.icons.chevronLeft,
      ),
    );
  }
}

enum AppChevronDirection { left, right }

class _AppPaperIcon extends StatelessWidget {
  const _AppPaperIcon({required this.path, this.color = AppColors.text});

  final String path;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: AppSizes.iconAction,
      height: AppSizes.iconAction,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
