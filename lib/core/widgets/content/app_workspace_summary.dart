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
    super.key,
    this.title,
    this.action,
  });

  final List<AppWorkspaceMetric> metrics;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (title != null || action != null) ...<Widget>[
              Row(
                children: <Widget>[
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.primaryText.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (action != null) ...<Widget>[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      child: Center(child: action),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double itemWidth = constraints.maxWidth < 300
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final AppWorkspaceMetric metric in metrics)
                      SizedBox(
                        width: itemWidth,
                        child: _WorkspaceMetricView(metric: metric),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceMetricView extends StatelessWidget {
  const _WorkspaceMetricView({required this.metric});

  final AppWorkspaceMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          metric.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sectionTitle.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
