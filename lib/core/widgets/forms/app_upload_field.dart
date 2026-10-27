import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppUploadField extends StatelessWidget {
  const AppUploadField({
    required this.title,
    required this.onPressed,
    this.description,
    this.icon = const Icon(Icons.upload_file_outlined),
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? description;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color foreground = enabled ? AppColors.text : AppColors.secondaryText;

    return Semantics(
      button: true,
      enabled: enabled && onPressed != null,
      label: title,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconTheme(
                    data: const IconThemeData(
                      color: AppColors.accent,
                      size: 28,
                    ),
                    child: icon,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.action.copyWith(color: foreground),
                  ),
                  if (description case final String description) ...<Widget>[
                    const SizedBox(height: 4),
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
    );
  }
}
