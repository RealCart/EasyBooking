import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A booking channel on «Подключите площадки»: a tap connects it, another
/// tap disconnects it again.
final class AddPropertyChannelRow extends StatelessWidget {
  const AddPropertyChannelRow({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.isConnected,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String description;

  /// `Подключить` or `Настроить`, shown while not connected.
  final String actionLabel;
  final bool isConnected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isConnected,
      child: InkWell(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 32,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        AppAssets.icons.calendar,
                        width: AppSizes.iconAppBar,
                        height: AppSizes.iconAppBar,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.xSmall,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.primaryText.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTypography.compactBody.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 112),
                  child: Text(
                    isConnected ? 'Подключено' : actionLabel,
                    textAlign: TextAlign.right,
                    style: AppTypography.compactBody.copyWith(
                      color: isConnected ? AppColors.success : AppColors.text,
                      fontWeight: isConnected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
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
