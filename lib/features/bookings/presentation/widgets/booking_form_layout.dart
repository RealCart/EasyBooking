import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_system_status_style.dart';

/// Layout of the new-booking steps: a header, a scrollable body with a
/// title and subtitle, and a footer that stays above the keyboard.
final class BookingFormLayout extends StatelessWidget {
  const BookingFormLayout({
    required this.header,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
    super.key,
  });

  final PreferredSizeWidget header;
  final String title;
  final String? subtitle;

  /// The form, or a loading or error placeholder.
  final Widget body;

  /// Hidden while there is nothing to submit.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final Widget? footer = this.footer;

    return AppSystemStatusRegion(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.pageGutter,
                    20,
                    AppSizes.pageGutter,
                    AppSpacing.xLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.compactScreenTitle.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppTypography.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      body,
                    ],
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}
