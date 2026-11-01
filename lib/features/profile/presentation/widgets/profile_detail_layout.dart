import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_failure_message.dart';

/// The frame of a profile settings screen: the header with a back button,
/// the scrollable [body], and an optional sticky [footer].
final class ProfileDetailLayout extends StatelessWidget {
  const ProfileDetailLayout({
    required this.title,
    required this.body,
    this.footer,
    this.action,
    this.isBackEnabled = true,
    super.key,
  });

  final String title;
  final Widget body;
  final Widget? footer;

  /// The trailing header action, such as «+».
  final Widget? action;

  /// Disables the back button, for example while a save is running.
  final bool isBackEnabled;

  @override
  Widget build(BuildContext context) {
    final Widget? footer = this.footer;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppDetailHeader(
              title: title,
              backSemanticLabel: 'Назад',
              showDivider: false,
              isBackEnabled: isBackEnabled,
              onBack: () => context.pop(),
              action: action,
            ),
            Expanded(child: body),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// A failed first load, with a retry.
final class ProfileLoadError extends StatelessWidget {
  const ProfileLoadError({
    required this.title,
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final String title;
  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pageGutter,
        vertical: AppSpacing.large,
      ),
      children: <Widget>[
        AppEmptyState(
          title: title,
          message: failure.profileMessage,
          icon: SvgPicture.asset(AppAssets.icons.alertCircle),
          actionLabel: 'Повторить',
          onAction: onRetry,
        ),
      ],
    );
  }
}

/// Placeholder rows shown while a settings screen loads for the first time.
final class ProfileListSkeleton extends StatelessWidget {
  const ProfileListSkeleton({this.rowCount = 5, super.key});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        18,
        AppSizes.pageGutter,
        0,
      ),
      children: <Widget>[
        const AppSkeleton(height: 16, width: 120),
        const SizedBox(height: AppSpacing.large),
        for (int index = 0; index < rowCount; index++) ...<Widget>[
          const Row(
            children: <Widget>[
              AppSkeleton(height: 40, width: 40, borderRadius: AppRadii.field),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppSkeleton(height: 16, width: 180),
                    SizedBox(height: AppSpacing.small),
                    AppSkeleton(height: 12, width: 120),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xLarge),
        ],
      ],
    );
  }
}

extension ProfileComingSoon on BuildContext {
  /// For actions that are shown by the design but not available yet.
  void showComingSoon() => showAppSnackbar('Скоро будет');
}
