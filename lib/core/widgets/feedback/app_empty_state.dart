import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.icon,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final Widget? icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon ??
                  const Icon(
                    Icons.search_off_rounded,
                    size: AppSpacing.xxxLarge,
                  ),
              const SizedBox(height: AppSpacing.large),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: AppSpacing.large),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
