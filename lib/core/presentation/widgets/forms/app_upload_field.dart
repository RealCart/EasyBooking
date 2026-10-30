import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppUploadField extends StatelessWidget {
  const AppUploadField({
    required this.title,
    required this.onPressed,
    this.description,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? description;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: title,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: isEnabled ? onPressed : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: .all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 168),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: IconTheme(
                        data: const IconThemeData(
                          color: AppColors.text,
                          size: 26,
                        ),
                        child:
                            icon ??
                            SvgPicture.asset(
                              AppAssets.icons.plus,
                              width: 26,
                              height: 26,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.action.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        color: AppColors.text,
                      ),
                    ),
                    if (description case final String description) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
