import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_flow_footer.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_progress_app_bar.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';

/// The frame of one «Добавить квартиру» step: the progress header, the
/// title and subtitle, the step's content, and the footer.
///
/// While the draft loads ([draftStatus]) the content is a skeleton; when it
/// fails, an error with [onRetry]; once loaded, [children].
final class AddPropertyStepLayout extends StatelessWidget {
  const AddPropertyStepLayout({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.draftStatus,
    required this.draftErrorMessage,
    required this.onRetry,
    required this.onBack,
    required this.footerMessage,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.children,
    this.isSubmitting = false,
    super.key,
  });

  static const int totalSteps = 3;

  final int step;
  final String title;
  final String subtitle;
  final RequestStatus draftStatus;

  /// Shown when [draftStatus] is [RequestStatus.failure].
  final String? draftErrorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final String footerMessage;
  final String primaryLabel;

  /// `null` while the draft is not loaded.
  final VoidCallback? onPrimaryPressed;
  final bool isSubmitting;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppProgressAppBar(
              title: 'Добавить квартиру',
              currentStep: step,
              totalSteps: totalSteps,
              backSemanticLabel: 'Назад',
              showDivider: false,
              onBack: onBack,
            ),
            // Not a lazy list: every form field must stay built so the
            // enclosing `Form` validates the fields scrolled out of view.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pageGutter,
                  AppSpacing.large,
                  AppSizes.pageGutter,
                  AppSpacing.xLarge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: AppTypography.compactScreenTitle.copyWith(
                          color: AppColors.text,
                        ),
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
                    if (draftStatus.isSuccess)
                      ...children
                    else if (draftStatus.isFailure)
                      AppEmptyState(
                        title: 'Не удалось загрузить черновик',
                        message: draftErrorMessage ?? '',
                        icon: SvgPicture.asset(AppAssets.icons.alertCircle),
                        actionLabel: 'Повторить',
                        onAction: onRetry,
                      )
                    else
                      const _DraftSkeleton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFlowFooter(
        message: footerMessage,
        messageStyle: AppTypography.caption.copyWith(
          color: AppColors.secondaryText,
        ),
        primaryLabel: primaryLabel,
        primaryLoading: isSubmitting,
        onPrimaryPressed: draftStatus.isSuccess ? onPrimaryPressed : null,
      ),
    );
  }
}

/// Placeholders for the step's fields while the draft loads.
final class _DraftSkeleton extends StatelessWidget {
  const _DraftSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
      ],
    );
  }
}
