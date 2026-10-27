import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppListingCard extends StatelessWidget {
  const AppListingCard({
    required this.title,
    required this.subtitle,
    required this.price,
    super.key,
    this.details,
    this.unitLabel,
    this.badgeLabel,
    this.image,
    this.action,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? details;
  final String? unitLabel;
  final String? badgeLabel;
  final Widget? image;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(16);

    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isNarrow = constraints.maxWidth < 360;
            final Widget content = Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (badgeLabel != null) ...<Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          badgeLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (details != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      details!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: price,
                                style: AppTypography.primaryText.copyWith(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (unitLabel != null)
                                TextSpan(
                                  text: ' ${unitLabel!}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                ],
              ),
            );

            if (image == null) {
              return content;
            }

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: image,
                    ),
                  ),
                  content,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: 136,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(15),
                      ),
                      child: image,
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
