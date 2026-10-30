import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

@immutable
class AppWorkspaceMetric {
  const AppWorkspaceMetric({required this.label, required this.value});
  final String label;
  final String value;
}

class AppWorkspaceSummary extends StatelessWidget {
  const AppWorkspaceSummary({
    required this.metrics,
    this.title,
    super.key,
  });
  final List<AppWorkspaceMetric> metrics;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title ?? '', style: AppTypography.primaryText),
              ),
            ],
          ),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int index = 0; index < metrics.length; index++)
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: index == 0
                            ? null
                            : const Border(
                                left: BorderSide(color: AppColors.border),
                              ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            metrics[index].value,
                            textAlign: TextAlign.center,
                            style: AppTypography.sectionTitle.copyWith(
                              fontSize: 22,
                              height: 34 / 22,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            metrics[index].label,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
