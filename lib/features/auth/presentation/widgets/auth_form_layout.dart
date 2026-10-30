import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_system_status_style.dart';

/// Layout shared by the auth screens: a header, a scrollable form with a
/// title and subtitle, and a footer that stays above the keyboard.
final class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    required this.header,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footer,
    super.key,
  });

  final Widget header;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
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
                    AppSpacing.large,
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
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xLarge),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.large,
                        children: children,
                      ),
                    ],
                  ),
                ),
              ),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}
