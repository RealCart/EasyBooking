import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';

final class AppHeaderBackButton extends StatelessWidget {
  const AppHeaderBackButton({
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;

  /// Disables and dims the button when `null`.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: IconButton(
          constraints: const BoxConstraints.tightFor(
            width: AppSizes.touchTarget,
            height: AppSizes.touchTarget,
          ),
          padding: EdgeInsets.zero,
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
      ),
    );
  }
}
