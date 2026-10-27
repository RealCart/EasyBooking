import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppConflictCard extends StatelessWidget {
  const AppConflictCard({
    required this.message,
    required this.primaryActionLabel,
    required this.title,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    super.key,
  });

  final String title;
  final String message;
  final String primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.all(
          Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.small),
                Expanded(child: Text(title, style: AppTypography.sectionTitle)),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(message, style: AppTypography.body),
            const SizedBox(height: AppSpacing.large),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final List<Widget> actions = <Widget>[
                  if (secondaryActionLabel != null)
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      child: Text(secondaryActionLabel!),
                    ),
                  FilledButton(
                    onPressed: onPrimaryAction,
                    child: Text(primaryActionLabel),
                  ),
                ];

                if (constraints.maxWidth < 300) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children:
                        actions
                            .expand(
                              (Widget action) => <Widget>[
                                action,
                                const SizedBox(height: AppSpacing.small),
                              ],
                            )
                            .toList()
                          ..removeLast(),
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children:
                      actions
                          .expand(
                            (Widget action) => <Widget>[
                              action,
                              const SizedBox(width: AppSpacing.small),
                            ],
                          )
                          .toList()
                        ..removeLast(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
